import numpy as np
import matplotlib.pyplot as plt
import datetime

def irig_pattern(clk_freq, sim_dur=2 ,timecode=None):
    """ clk_freq in mhz
        sim_dur: simulation duration in seconds
    """
    sec = clk_freq*10**6   ##10ms of resolution
    interval = sec/100.
    if(timecode is None):
        timecode = datetime.datetime.now()
    ##0 --> logic zero
    ##1 --> logic one
    ##2 --> pos identifier
    simbols = np.zeros(int(sim_dur*100))
    start_point = np.random.randint(2,1*100)
    simbols[start_point-1] = 2
    simbols[start_point] = 2
    for i in range(start_point-1):
        simbols[i] = np.random.randint(2)
    ##seconds
    idx = start_point+1
    sec = timecode.second
    u_sec = format(sec%10, '#06b')[2:] ##6: 2 for 0b and 4 for the bits
    u_sec = u_sec[::-1]                     ##irig first send the lsb
    for i in range(4):
        simbols[idx+i] = u_sec[i]
    simbols[idx+4] = 0              ##5bit is a identity bit and its 0 
    #
    idx += 5
    d_sec = format(sec//10, '#05b')[2:]
    d_sec = d_sec[::-1]
    for i in range(3):
        simbols[idx+i] = d_sec[i]
    simbols[idx+3] = 2              ##position identifier
    #minutes
    idx += 4
    minute = timecode.minute
    u_min = format(minute%10, '#06b')[2:] ##6: 2 for 0b and 4 for the bits
    u_min = u_min[::-1]                     ##irig first send the lsb
    for i in range(4):
        simbols[idx+i] = u_min[i]
    simbols[idx+4] = 0              #identity bit
    #
    idx += 5
    d_min = format(minute//10, '#05b')[2:]
    d_min = d_min[::-1]
    for i in range(3):
        simbols[idx+i] = d_min[i]
    simbols[idx+3] = 0      #empty
    simbols[idx+4] = 2      #pos id
    #ipdb.set_trace()
    #hour
    idx+=5
    hr = timecode.hour
    u_hr = format(hr%10, '#06b')[2:] ##6: 2 for 0b and 4 for the bits
    u_hr = u_hr[::-1]                     ##irig first send the lsb
    for i in range(4):
        simbols[idx+i] = u_hr[i]
    simbols[idx+4] = 0              #identity bit
    #
    idx+=5
    d_hr = format(hr//10, '#04b')[2:]
    d_hr = d_hr[::-1]
    for i in range(2):
        simbols[idx+i] = d_hr[i]
    simbols[idx+i+1] = 0    #empty
    simbols[idx+i+2] = 0    #empty
    simbols[idx+i+3] = 2    #pos id
    #days
    idx += 5
    day = timecode.timetuple().tm_yday
    u_day = format(day%10, '#06b')[2:] ##6: 2 for 0b and 4 for the bits
    u_day = u_day[::-1]                     ##irig first send the lsb
    for i in range(4):
        simbols[idx+i] = u_day[i]
    simbols[idx+4] = 0              #identity bit
    #
    idx+=5
    d_day = format((day%100)//10, '#06b')[2:] ##6: 2 for 0b and 4 for the bits
    d_day = d_day[::-1]                     ##irig first send the lsb
    for i in range(4):
        simbols[idx+i] = d_day[i]
    simbols[idx+4] = 2              #identity bit
    #
    idx+=5
    c_day = format(day//100, '#04b')[2:] 
    c_day = c_day[::-1]
    for i in range(2):
        simbols[idx+i] = c_day[i]
    #in this part all are zeros
    simbols[idx+9] = 2
    #here there are control signals
    idx +=10
    for i in range(9):
        simbols[idx+i] = np.random.randint(2) 
    simbols[idx+i+1] = 2
    #
    idx +=10
    for i in range(9):
        simbols[idx+i] = np.random.randint(2) 
    simbols[idx+i+1] = 2
    #
    idx +=10
    for i in range(9):
        simbols[idx+i] = np.random.randint(2) 
    simbols[idx+i+1] = 2
    ##straight binary seconds (of the day!)
    idx +=10
    sbs = sec+minute*60+hr*60*60
    sbs_bin = format(sbs, '#019b')[2:]
    sbs_bin = sbs_bin[::-1]
    for i in range(9):
        simbols[idx+i] = sbs_bin[i]
    simbols[idx+i+1] = 2
    #
    idx += 10
    for i in range(8):
        simbols[idx+i] = sbs_bin[9+i]
    simbols[idx+i+1] = 0
    simbols[idx+i+2] = 2

    #the next will be the start of other packet
    #simbols[idx+i+3] = 2
    
    #for the next we are going to write random vals
    idx = idx+i+2
    rest = len(simbols)-idx-1
    for i in range(1,rest):
        if(((i%10)==1) or ((i%101)==1)):
            simbols[idx+i] = 2
        else:
            simbols[idx+i] = np.random.randint(2)
    return simbols
