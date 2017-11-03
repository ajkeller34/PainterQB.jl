# these are examples of response types and measure functions for those types
# these are meant to illustrate, in general, how one sets up the Digitizer for readout

export SingleChStream
export SingleChTrig
export SingleChAnalogTrig
export TwoChTrig
export TwoChAnalogTrig
export ThreeChAnalogTrig
export IQTrigResponse

"""
Response type for continuously measuring the output of a channel until a given timeout.
The timeout is measured in terms of milliseconds. It is assumed that the data collection is small
enough that there is no need to configure buffers.
"""
mutable struct SingleChStream <: Response
    dig::InsDigitizerM3102A
    ch::Int #ch for channel
    timeout::Float64
end

function measure(resp::SingleChStream)
#make daq_points 1.1 times the timeout so DAQRead finishes from reaching the timeout
    dig = resp.dig
    ch = resp.ch
    timeout  = resp.timeout
    daq_points = Int(ceil(10 * (resp.timeout* (500e6)))) # making daq_points much larger than data from timeout


    dig[DAQTrigMode, ch] = :Auto
    dig[DAQCycles, ch] = -1 #infinite number of cycles
    dig[DAQPointsPerCycle, ch] = daq_points

    daq_start(dig, ch)
    sleep(0.001)
    data = daq_read(dig, ch, daq_points, Int(ceil(timeout*10e3)))
    return data
end

mutable struct SingleChTrig <: Response
    dig::InsDigitizerM3102A
    ch::Int #ch for channel
    daq_cycles::Int
    points_per_cyle::Int
    delay::Int
    trig_source::Any
end

function measure(resp::SingleChTrig)
    dig = resp.dig
    ch = resp.ch
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    dig[DAQTrigMode, ch] = :External
    dig[ExternalTrigSource, ch] = resp.trig_source
    data = measure_singleCh_general(resp)
    return data
end

mutable struct SingleChAnalogTrig <: Response
    dig::InsDigitizerM3102A
    ch::Int #ch for channel
    daq_cycles::Int
    points_per_cyle::Int
    delay::Int
    trig_source::Int
    threshold::Float64
end

function measure(resp::SingleChAnalogTrig)
    dig = resp.dig
    ch = resp.ch
    dig[AnalogTrigSource, ch] = resp.trig_source
    dig[AnalogTrigBehavior, ch] = :RisingAnalog
    dig[AnalogTrigThreshold, ch] = resp.threshold
    dig[DAQTrigMode, ch] = :Analog
    data = measure_singleCh_general(resp)
    return data
end

function measure_singleCh_general(resp::Response)
    dig = resp.dig
    ch = resp.ch
    daq_points = resp.points_per_cyle * resp.daq_cycles
    dig[DAQPointsPerCycle, ch] = resp.points_per_cyle
    dig[DAQCycles, ch] = resp.daq_cycles
    dig[DAQTrigDelay, ch] = resp.delay

    SD_AIN_DAQflush(dig.ID, ch)
    daq_stop(dig, ch)
    daq_start(dig, ch)
    data = daq_read(dig, ch, daq_points, 10)
    data = data * (dig[FullScale, ch])/2^15
    return data
end

mutable struct TwoChTrig <: Response
    dig::InsDigitizerM3102A
    ch1::Int #ch for channel
    ch2::Int
    daq_cycles::Int
    points_per_cyle::Int
    delay::Int
    trig_source::Any
end

function measure(resp::TwoChTrig)
    dig = resp.dig
    ch1 = resp.ch1
    ch2 = resp.ch2
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    for ch in [ch1, ch2]
        dig[DAQTrigMode, ch] = :External
        dig[ExternalTrigSource, ch] = resp.trig_source
    end
    data1, data2 = measure_twoCh_general(resp)
    return data1, data2
end

mutable struct TwoChAnalogTrig <: Response
    dig::InsDigitizerM3102A
    ch1::Int #ch for channel
    ch2::Int
    daq_cycles::Int
    points_per_cyle::Int
    delay::Int
    trig_source::Int
    threshold::Float64
end

function measure(resp::TwoChAnalogTrig)
    dig = resp.dig
    ch1 = resp.ch1
    ch2 = resp.ch2
    for ch in [ch1, ch2]
        dig[DAQTrigMode, ch] = :Analog
        dig[AnalogTrigSource, ch] = resp.trig_source
        dig[AnalogTrigBehavior, ch] = :RisingAnalog
        dig[AnalogTrigThreshold, ch] = resp.threshold
    end
    data1, data2 = measure_twoCh_general(resp)
    return data1, data2
end

function measure_twoCh_general(resp::Response)
    dig = resp.dig
    ch1 = resp.ch1
    ch2 = resp.ch2
    daq_points = resp.points_per_cyle * resp.daq_cycles
    for ch in [ch1, ch2]
        dig[DAQPointsPerCycle, ch] = resp.points_per_cyle
        dig[DAQCycles, ch] = resp.daq_cycles
        dig[DAQTrigDelay, ch] = resp.delay
    end
    daq_start(dig, ch1, ch2)
    data1 = daq_read(dig, ch1, daq_points, 10)
    data1 = data1 * (dig[FullScale, ch1])/2^15
    data2 = daq_read(dig, ch2, daq_points, 10)
    data2 = data2 * (dig[FullScale, ch2])/2^15
    return data1, data2
end

mutable struct IQTrigResponse <: Response
    dig::InsDigitizerM3102A
    I_ch::Int #ch for channel
    Q_ch::Int
    daq_cycles::Int
    points_per_cyle::Int
    delay::Int
    trig_source::Any
    freq::Float64
end

function measure(resp::IQTrigResponse)
    two_ch_resp = TwoChTrig(resp.dig, resp.ch1, resp.ch2, resp.daq_cycles, resp.points_per_cyle,
              resp.delay, resp.trig_source)
    I_data, Q_data = measure(two_ch_resp)
    #Daniel sanks thesis
end

mutable struct ThreeChAnalogTrig <: Response
    dig::InsDigitizerM3102A
    ch1::Int #ch for channel
    ch2::Int
    ch3::Int
    daq_cycles::Int
    points_per_cyle::Int
    delay::Int
    trig_source::Int
    threshold::Float64
end

function measure(resp::ThreeChAnalogTrig)
    dig = resp.dig
    ch1 = resp.ch1
    ch2 = resp.ch2
    ch3 = resp.ch3
    daq_points = resp.points_per_cyle * resp.daq_cycles
    for ch in [ch1, ch2, ch3]
        dig[DAQTrigMode, ch] = :Analog
        dig[AnalogTrigSource, ch] = resp.trig_source
        dig[AnalogTrigBehavior, ch] = :RisingAnalog
        dig[AnalogTrigThreshold, ch] = resp.threshold
        dig[DAQPointsPerCycle, ch] = resp.points_per_cyle
        dig[DAQCycles, ch] = resp.daq_cycles
        dig[DAQTrigDelay, ch] = resp.delay
    end
    daq_start(dig, ch1, ch2, ch3)
    data1 = daq_read(dig, ch1, daq_points, 10)
    data1 = data1 * (dig[FullScale, ch1])/2^15
    data2 = daq_read(dig, ch2, daq_points, 10)
    data2 = data2 * (dig[FullScale, ch2])/2^15
    data3 = daq_read(dig, ch3, daq_points, 10)
    data3 = data3 * (dig[FullScale, ch3])/2^15
    return data1, data2, data3
end
