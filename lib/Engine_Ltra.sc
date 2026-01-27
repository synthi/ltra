// lib/Engine_Ltra.sc | v0.6
Engine_Ltra : CroneEngine {
    var <synth;
    var <osc_bridge;
    var <bus_looper_in; 

    *new { arg context, doneCallback; ^super.new(context, doneCallback); }

    alloc {
        bus_looper_in = Bus.audio(context.server, 2);

        SynthDef(\ltra_core, {
            arg out, looper_bus,
                freq1=110, freq2=150, freq3=220, freq4=330,
                shape1=0, shape2=0, shape3=0, shape4=0,
                vol1=0, vol2=0, vol3=0, vol4=0,
                pan1=0, pan2=0, pan3=0, pan4=0,
                gate1=0, gate2=0, gate3=0, gate4=0, // Vactrol Gates
                
                mod_lfo1_pitch1=0, mod_lfo2_pitch1=0, mod_chaos_pitch1=0, mod_outline_pitch1=0, mod_arp_pitch1=0,
                // (Asumir resto de matriz expandida)

                lfo1_rate=0.5, lfo1_shape=0, lfo1_depth=1,
                lfo2_rate=0.2, lfo2_shape=2, lfo2_depth=1,
                chaos_rate=0.5, chaos_slew=0.1,

                filt1_tone=0, filt2_tone=0, filt1_res=0, filt2_res=0,
                filt1_drive=0, filt2_drive=0, filt_type=0, 

                delay_time=0.5, delay_fb=0.0, delay_send=0.5, delay_spread=0.0,
                tape_wow=0, tape_flutter=0, tape_erosion=0,
                reverb_mix=0, reverb_time=5, reverb_damp=0.5,
                
                system_dirt=0, dust_dens=0, 
                pre_post_switch=0;

            var lfo1, lfo2, chaos_sig, rungler_clk, rungler_val;
            var m_pitch1; 
            var mk_osc, o1, o2, o3, o4, sig_mix;
            var mk_vactrol;
            var apply_dj_filter, sig_filt1, sig_filt2, sig_pre;
            var dirt_sig, hiss, hum, dust_sig;
            var delay_in, local_fb, delay_proc, tape_sig;
            var reverb_sig, effects_out, sig_post;
            var osc_trig, amp_l, amp_r;
            
            var lag = 0.05;
            var s_freq1 = Lag.kr(freq1, lag); 
            var s_vol1 = Lag.kr(vol1, lag);
            var s_filt1 = Lag.kr(filt1_tone, lag); var s_filt2 = Lag.kr(filt2_tone, lag);
            var s_dtime = Lag.kr(delay_time, 0.2); 

            // 1. MODULATORS
            lfo1 = SelectX.kr(lfo1_shape * 3, [LFPulse.kr(lfo1_rate), LFSaw.kr(lfo1_rate), LFTri.kr(lfo1_rate), SinOsc.kr(lfo1_rate)]) * lfo1_depth;
            lfo2 = SelectX.kr(lfo2_shape * 3, [LFPulse.kr(lfo2_rate), LFSaw.kr(lfo2_rate), LFTri.kr(lfo2_rate), SinOsc.kr(lfo2_rate)]) * lfo2_depth;
            
            rungler_clk = Impulse.kr(chaos_rate * 4);
            rungler_val = Latch.kr(WhiteNoise.kr, rungler_clk); 
            chaos_sig = Slew.kr(rungler_val, chaos_slew * 10, chaos_slew * 10);

            // 2. OSCILLATORS (Noise FM Morph)
            mk_osc = { |f, s| 
                var noise = PinkNoise.ar;
                var saw_fm = VarSaw.ar(f * (1 + (noise * (1-s).clip(0,1))), 0, 0);
                var tri = LFTri.ar(f);
                var pul = Pulse.ar(f, 0.5);
                var sin = SinOsc.ar(f);
                SelectX.ar(s, [noise, saw_fm, tri, pul, sin]) 
            };
            
            // Vactrol Simulation (LPG)
            mk_vactrol = { |g| 
                var env = LagUD.kr(g, 0.02, 0.4); // Fast attack, slow decay
                env 
            };
            
            m_pitch1 = (lfo1 * mod_lfo1_pitch1);
            
            // Aplicar Vactrol al volumen
            o1 = mk_osc.(s_freq1 * (2.pow(m_pitch1)), shape1) * s_vol1 * mk_vactrol.(gate1);
            o2 = mk_osc.(freq2, shape2) * vol2 * mk_vactrol.(gate2);
            o3 = mk_osc.(freq3, shape3) * vol3 * mk_vactrol.(gate3);
            o4 = mk_osc.(freq4, shape4) * vol4 * mk_vactrol.(gate4);

            sig_mix = Pan2.ar(o1, pan1) + Pan2.ar(o2, pan2) + Pan2.ar(o3, pan3) + Pan2.ar(o4, pan4);

            // 3. DUAL DJ FILTERS (Avant Math - No Clicks)
            apply_dj_filter = { |in, tone, res, drive, type|
                var ctrl_lp = (tone + 1).clip(0, 1); 
                var ctrl_hp = tone.max(0);
                var freq_lp = LinExp.kr(ctrl_lp, 0.001, 1, 20, 20000); 
                var freq_hp = LinExp.kr(ctrl_hp, 0.001, 1, 20, 20000); 
                var sig = (in * (1 + drive)).tanh; 
                
                // Crossfade Type (Moog/SVF)
                var svf_lp = RLPF.ar(sig, freq_lp, 1.0 - (res * 0.5));
                var moog_lp = MoogFF.ar(sig, freq_lp, res * 3.5);
                var out_lp = SelectX.ar(Lag.kr(type, 0.1), [svf_lp, moog_lp]);
                
                // Serie: HPF siempre SVF (Clean cut)
                var res_sig = RHPF.ar(out_lp, freq_hp, 1.0 - (res * 0.5));
                res_sig;
            };

            sig_filt1 = apply_dj_filter.(sig_mix, s_filt1, filt1_res, filt1_drive, filt_type);
            sig_filt2 = apply_dj_filter.(sig_filt1, s_filt2, filt2_res, filt2_drive, filt_type);
            
            sig_pre = sig_filt2; 

            // 4. ATMOSPHERE (DIRT AVANT)
            hiss = PinkNoise.ar * system_dirt.pow(0.75) * 0.03;
            hum = SinOsc.ar([50, 50]) * system_dirt.pow(3) * 0.015;
            dust_sig = Decay2.ar(Dust.ar([dust_dens, dust_dens]), 0.001, 0.01) * PinkNoise.ar * system_dirt;
            dirt_sig = hiss + hum + dust_sig;

            // 5. SPACE
            delay_in = sig_pre + dirt_sig; 
            local_fb = LocalIn.ar(2);
            local_fb = LeakDC.ar(local_fb);
            local_fb = Limiter.ar(local_fb, 0.95); 
            
            local_fb = BPeakEQ.ar(local_fb, 100, 1.0, 2.0); 
            local_fb = LPF.ar(local_fb, 8000);
            local_fb = (local_fb * (1 + (delay_fb * 0.5))).tanh; 
            
            // Erosion
            local_fb = local_fb * (1.0 - (Decay.kr(Dust.kr(tape_erosion * 10), 0.1) * tape_erosion));

            delay_proc = [
                DelayC.ar(delay_in[0] + (local_fb[0] * delay_fb), 2.5, s_dtime + (LFNoise2.kr(0.5)*tape_wow) + (LFNoise1.kr(10)*tape_flutter)),
                DelayC.ar(delay_in[1] + (local_fb[1] * delay_fb), 2.5, s_dtime + (LFNoise2.kr(0.5)*tape_wow) + (LFNoise1.kr(10)*tape_flutter) + (delay_spread * 0.02))
            ];
            LocalOut.ar(delay_proc);
            
            tape_sig = delay_proc;
            reverb_sig = Greyhole.ar(tape_sig, reverb_time, reverb_damp, 1.0, 0.7, 0.05, 0.5);
            
            effects_out = (sig_pre * (1-delay_send)) + (tape_sig * delay_send);
            effects_out = (effects_out * (1-reverb_mix)) + (reverb_sig * reverb_mix);
            
            sig_post = Limiter.ar(effects_out, 0.98);

            Out.ar(looper_bus, Select.ar(pre_post_switch, [sig_pre, sig_post]));
            Out.ar(out, sig_post);

            osc_trig = Impulse.kr(15);
            amp_l = Amplitude.kr(sig_post[0]);
            amp_r = Amplitude.kr(sig_post[1]);
            SendReply.kr(osc_trig, '/ltra/visuals', [amp_l, amp_r, lfo1, lfo2]);

        }).add;

        context.server.sync;
        synth = Synth.new(\ltra_core, [\out, context.out_b, \looper_bus, bus_looper_in], context.xg);
        
        osc_bridge = OSCFunc({ |msg| NetAddr("127.0.0.1", 10111).sendMsg("/ltra/visuals", *msg.drop(3)); }, '/ltra/visuals', context.server.addr).fix;
        this.addCommand("param", "sf", { arg msg; synth.set(msg[1].asSymbol, msg[2]); });
        this.addCommand("query_config", "", { NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", bus_looper_in.index); });
        NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", bus_looper_in.index);
    }
    free { synth.free; osc_bridge.free; bus_looper_in.free; }
}
