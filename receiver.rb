#!/usr/bin/env ruby

require 'aws-sdk'
require 'serialport'
require 'pry'

BAROMETER_HIGHT_METERS = 110;
GAS_OFFSET = 203820;
POWER_OFFSET = 1939560;

@dynamo = Aws::DynamoDB::Client.new(
    region: 'us-east-1'
)

def calculate_pressure(val)
  #Pressure drops 12 Pa per 1m;
  #translate result to hPa
  (val + BAROMETER_HIGHT_METERS * 12) / 100
end

def calculate_kwh()

end

@last_value = {}

@process = {
    #Sensors
    '4' => lambda do |v|
      [v[0].round(1),v[1].round(1)]
    end,
    '5' => lambda do |v|
      v[2] = calculate_pressure(v[2])
      [v[0].round(1), v[1].round(1), v[2].round(1) ]
    end,
    #Gas
    '10' => lambda do |v|
      [v.first.to_i + GAS_OFFSET]
    end,
    #Power
    '20' => lambda do |v|
      last = @last_value['20'] || {'time' => 0, 'data' => [0]}
      current_watt_hours = v.first.to_i + POWER_OFFSET
      last_watt_hours = last['data'].first
      time_diff = ( Time.now.to_i - last['time'] ) / 3600.0
      watt_hour_diff = current_watt_hours - last_watt_hours
      current_watt = watt_hour_diff /  time_diff
      [current_watt_hours, current_watt.to_i]
    end
}

def process(id, vals)
  vals.map!(&:to_f)
  @process[id].call(vals)
end

def items(raw)
  data = raw.chomp.split(',')
  id, *vals = data

  item = {
      'id' => id,
      'time' => Time.now.to_i,
      'data' => process(id, vals)
  }
  @last_value[id] = item;
  p item
end

def put(item)
  @dynamo.put_item({
                       table_name: "sensors",
                       item: item
                   })
end

#binding.pry

# Main
ser = SerialPort.new("/dev/ttyAMA0", 115200)

loop do
  begin
    data = ser.readline || ''
    unless data.empty?
      put(items(data))
    end
  rescue
    sleep(2)
  end
end