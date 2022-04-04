import "./index.css";

import flags from "./flags.json";

import { Elm } from "./elm/Main.elm";

function startAudio(e){if(window.AudioContext=window.AudioContext||window.webkitAudioContext||!1,window.AudioContext){let s=[],d=new AudioContext,l={},p=0;function o(o,t){let n=new XMLHttpRequest;n.open("GET",o,!0),n.responseType="arraybuffer",n.onerror=function(){e.ports.audioPortFromJS.send({type:0,requestId:t,error:"NetworkError"})},n.onload=function(){d.decodeAudioData(n.response,function(n){let a=s.length,r=o.endsWith(".mp3");s.push({isMp3:r,buffer:n}),e.ports.audioPortFromJS.send({type:1,requestId:t,bufferId:a,durationInSeconds:(n.length-(r?p:0))/n.sampleRate})},function(o){e.ports.audioPortFromJS.send({type:0,requestId:t,error:o.message})})},n.send()}function t(e,o){return(e-o)/1e3+d.currentTime}function n(e,o,t){o?(e.loopStart=t+o.loopStart/1e3,e.loopEnd=t+o.loopEnd/1e3,e.loop=!0):e.loop=!1}function a(e,o,t,n,a){let r=(a-e)/(t-e);return Number.isFinite(r)?r*(n-o)+o:o}function r(e,o){return e.map(e=>{let n=d.createGain();n.gain.setValueAtTime(e[0].volume,0),n.gain.linearRampToValueAtTime(e[0].volume,0);let r=t(o,o);for(let u=1;u<e.length;u++){let i=e[u-1],s=t(i.time,o),d=e[u],l=t(d.time,o);if(l>r&&r>=s){let e=a(s,i.volume,l,d.volume,r);n.gain.setValueAtTime(e,0),n.gain.linearRampToValueAtTime(d.volume,l)}else l>r?n.gain.linearRampToValueAtTime(d.volume,l):n.gain.setValueAtTime(d.volume,0)}return n})}function u(e){for(let o=1;o<e.length;o++)e[o-1].connect(e[o])}function i(e,o,a,i,s,l,m,c){let f=e.buffer,b=e.isMp3?p/d.sampleRate:0,g=d.createBufferSource();g.buffer=f,g.playbackRate.value=c,n(g,m,b);let A=r(a,l),T=d.createGain();if(T.gain.setValueAtTime(o,0),u([g,T,...A,d.destination]),i>=l)g.start(t(i,l),b+s/1e3);else{let e=(l-i)/1e3;g.start(0,e+b+s/1e3)}return{sourceNode:g,gainNode:T,volumeAtGainNodes:A}}e.ports.audioPortFromJS.send({type:2,samplesPerSecond:d.sampleRate}),e.ports.audioPortToJS.subscribe(e=>{let t=(new Date).getTime();for(let o=0;o<e.audio.length;o++){let a=e.audio[o];switch(a.action){case"stopSound":{let e=l[a.nodeGroupId];l[a.nodeGroupId]=null,e.nodes.sourceNode.stop(),e.nodes.sourceNode.disconnect(),e.nodes.gainNode.disconnect(),e.nodes.volumeAtGainNodes.map(e=>e.disconnect());break}case"setVolume":l[a.nodeGroupId].nodes.gainNode.gain.setValueAtTime(a.volume,0);break;case"setVolumeAt":{let e=l[a.nodeGroupId];e.nodes.volumeAtGainNodes.map(e=>e.disconnect()),e.nodes.gainNode.disconnect();let o=r(a.volumeAt,t);u([e.nodes.gainNode,...o,d.destination]),e.nodes.volumeAtGainNodes=o;break}case"setLoopConfig":{let e=l[a.nodeGroupId],o=s[e.bufferId].isMp3?p/d.sampleRate:0;n(e.nodes.sourceNode,e.loop,o);break}case"setPlaybackRate":l[a.nodeGroupId].nodes.sourceNode.playbackRate.setValueAtTime(a.playbackRate,0);break;case"startSound":{let e=i(s[a.bufferId],a.volume,a.volumeTimelines,a.startTime,a.startAt,t,a.loop,a.playbackRate);l[a.nodeGroupId]={bufferId:a.bufferId,nodes:e};break}}}for(let t=0;t<e.audioCmds.length;t++)o(e.audioCmds[t].audioUrl,e.audioCmds[t].requestId)})}else console.log("Web audio is not supported in your browser.")}


const app = Elm.Main.init({ node: document.getElementById("app"), flags });


startAudio(app);

if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register(
        new URL('service-worker.js', import.meta.url),
        {type: 'module', scope: '.'}
      );
}