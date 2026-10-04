"""Original deterministic procedural music/SE. No sampled music or external sounds."""
from pathlib import Path
import numpy as np, wave, subprocess, json
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'godot/audio'
OUT.mkdir(exist_ok=True)
rng=np.random.default_rng(20261004)
def save(name,data):
 data=np.asarray(data);peak=float(np.abs(data).max());data=data*min(1,.82/max(peak,1e-9))
 with wave.open(str(OUT/(name+'.wav')),'wb') as f:
  f.setnchannels(1 if data.ndim==1 else data.shape[1]);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((data*32767).astype('<i2').tobytes())
 return {'name':name,'seconds':len(data)/RATE,'peak':float(np.abs(data).max()),'rms':float(np.sqrt(np.mean(data**2)))}
def hz(note):return 440*2**((note-69)/12)
L=64;N=L*RATE;music=np.zeros((N,2))
def add_key(note,start,length=6,gain=.10,pan=0):
 t=np.arange(int(length*RATE))/RATE;freq=hz(note)
 env=(1-np.exp(-t*20))*np.exp(-t/1.6)*(1-np.clip((t-length+.5)/.5,0,1))
 signal=env*(np.sin(2*np.pi*freq*t)+.18*np.sin(2*np.pi*freq*2*t)*np.exp(-t/1.2)+.07*np.sin(2*np.pi*freq*3*t))*gain
 inds=(int(start*RATE)+np.arange(len(t)))%N
 music[inds,0]+=signal*np.sqrt((1-pan)/2);music[inds,1]+=signal*np.sqrt((1+pan)/2)
# Am(add9), Fmaj7, C(add9), Gsus2: sparse original voicings.
chords=[[45,52,59,64],[41,48,55,64],[48,55,62,67],[43,50,57,62]]
for c,notes in enumerate(chords):
 for k,n in enumerate(notes):add_key(n,c*16+1+k*2.5,pan=(-.3 if k%2 else .3))
 add_key(notes[-1]+12,c*16+12,.0+4,.06,.15)
 # Long smooth low pad, periodic wrap for continuous loop.
 t=np.arange(24*RATE)/RATE;env=np.sin(np.pi*t/24)**2
 signal=(np.sin(2*np.pi*hz(notes[0])*t)+.3*np.sin(2*np.pi*hz(notes[1])*t))*.035*env
 inds=(c*16*RATE+np.arange(len(t)))%N
 music[inds,:]+=signal[:,None]
music *= 3
metrics=[save('quiet_chamber',music)]
subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(OUT/'quiet_chamber.wav'),'-c:a','libvorbis','-q:a','4',str(OUT/'quiet_chamber.ogg')],check=True)
(OUT/'quiet_chamber.wav').unlink()
def effect(name,duration,kind):
 t=np.arange(int(duration*RATE))/RATE
 attack=1-np.exp(-t*90);tail=np.clip(1-t/duration,0,1)**2
 if kind=='paper':
  noise=rng.normal(0,1,len(t));smooth=np.convolve(noise,np.ones(6)/6,mode='same');x=(noise-smooth)*.075*attack*tail*(.4+.6*np.sin(np.pi*t/duration)**2)
 elif kind=='hit': x=(np.sin(2*np.pi*(105*t-18*t*t))+.15*rng.normal(0,1,len(t)))*.18*attack*tail
 else:
  notes={'select':[76],'confirm':[64,71],'block':[52,59,64],'intervene':[69,64],'growth':[60,64,67,72],'victory':[48,55,60,64,67]}[kind]
  x=np.zeros(len(t))
  for k,n in enumerate(notes):
   offset=k*.065;u=np.maximum(0,t-offset);env=(t>=offset)*(1-np.exp(-u*80))*np.exp(-u/0.24)*tail
   x+=(np.sin(2*np.pi*hz(n)*u)+.12*np.sin(4*np.pi*hz(n)*u))*env*.12/np.sqrt(len(notes))
 return save(name,x*2)
for name,dur,kind in [('select',.12,'select'),('paper',.22,'paper'),('confirm',.25,'confirm'),('hit',.22,'hit'),('block',.35,'block'),('intervene',.35,'intervene'),('growth',.6,'growth'),('victory',1.0,'victory')]:metrics.append(effect(name,dur,kind))
# Measure the final-to-first sample step of the wrapped source mix.
Path(OUT/'audio_manifest.json').write_text(json.dumps({'generator':'scripts/generate_audio.py','seed':20261004,'sampleRate':RATE,'original':True,'duration':L,'loopBoundaryDelta':float(np.abs(music[0]-music[-1]).max()),'tracks':metrics},indent=2)+'\n')
print('Generated original quiet 64s BGM and 8 SE clips')
