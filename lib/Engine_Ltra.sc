// lib/Engine_Ltra.sc | v1.5.6
// FIX: FxTape and FxBlossom Integration

Engine_Ltra : CroneEngine {
    var <synth;
    var <osc_bridge;

    *new { arg context, doneCallback; ^super.new(context, doneCallback); }

    alloc {
        SynthDef(\ltra_core, {
            arg out,
                freq1=110, freq2=150, freq3=220, freq4=330,
                shape1=2, shape2=2, shape3=2, shape4=2,
                vol1=0.0, vol2=0.0, vol3=0.0, vol4=0.0,
                pan1=0, pan2=0, pan3=0, pan4=0,
                drift1=0, drift2=0, drift3=0, drift4=0, 
                spread1=0, spread2=0, spread3=0, spread4=0, 
                gate1=0, gate2=0, gate3=0, gate4=0,
                t_arp1=0, t_arp2=0, t_arp3=0, t_arp4=0,
                arp_cv1=0, arp_cv2=0, arp_cv3=0, arp_cv4=0,
                lfo1_rate=0.5, lfo1_shape=0, lfo1_depth=1,
                lfo2_rate=0.2, lfo2_shape=2, lfo2_depth=1,
                chaos_rate=0.5, chaos_slew=0.1, chaos_amp=1.0, 
                outline_source=0, outline_gain=1.0,
                filt1_cutoff=32, filt2_cutoff=14200, 
                filt1_res=0, filt2_res=0,
                filt1_type=1, filt2_type=0, 
                filt1_drive=0, filt2_drive=0, 
                // FxTape Params
                fx_tape_time=0.3, fx_tape_feedback=0.4, fx_tape_wow_flutter=0.1,
                fx_tape_erosion=0.0, fx_tape_drive=1.0, fx_tape_tone=1, delay_send=0.5,
                // FxBlossom Params
                fx_blossom_decay=4.75, fx_blossom_bloom=1.80, fx_blossom_damp=3500,
                fx_blossom_predelay=0.110, fx_blossom_mod_rate=0.300, fx_blossom_mod_depth=0.002, reverb_mix=0.0,
                system_dirt=0, dust_dens=0, 
                clear_trig=0, t_reset=0;

            var lfo1, lfo2, chaos_sig, rungler_clk, rungler_val;
            var outline_sig, env_int, env_ext;
            var m_pitch1, m_pitch2, m_pitch3, m_pitch4;
            var m_amp1, m_amp2, m_amp3, m_amp4;
            var m_shape1, m_shape2, m_shape3, m_shape4;
            var m_filt1, m_filt2, m_delay_t, m_delay_f;
            var o1, o2, o3, o4, sig_mix;
            var sig_filt1, sig_filt2, sig_pre;
            var dirt_sig, hiss, hum, dust_sig;
            var effects_out, sig_post;
            var osc_trig, amp_l, amp_r;
            var lag = 0.05;
            var s_freq1, s_freq2, s_freq3, s_freq4;
            var s_vol1, s_vol2, s_vol3, s_vol4;
            var s_filt1, s_filt2;
            var vca1, vca2, vca3, vca4;
            
            // FxTape Vars
            var tape_in, local_in, shared_wow, shared_flutter, shared_mod;
            var shared_dust_trig, shared_dropout_env, dt_mono, tape_del_mono;
            var sat_mono, ero_lpf_freq, ero_bass_cut, filt_mono, tone_freq, tone_filt_mono, final_mono;
            var skew_lfo, skew_l, skew_r, cross_l, cross_r, eq_var_l, eq_var_r;
            var tape_sig_l, tape_sig_r;
            var time_kr, fb_kr, wf_kr, ero_kr, drive_kr, tone_kr;

            // FxBlossom Vars
            var rev_in, lfo_l, lfo_r, combs_l, combs_r, cross_l_rev, cross_r_rev;
            var ap_l, ap_r, rev_filt_l, rev_filt_r, rev_out_l, rev_out_r;
            var decay_kr, bloom_kr, damp_kr, predelay_kr, mod_rate_kr, mod_depth_kr;
            var prime_combs_l = #[0.031229, 0.037270, 0.043979, 0.050354, 0.057270, 0.064770];
            var prime_combs_r = #[0.031479, 0.037729, 0.044354, 0.050479, 0.057354, 0.064979];
            var prime_ap_l = #[0.011270, 0.031729];
            var prime_ap_r = #[0.011604, 0.031895];
            
            var d_sig1 = (LFNoise2.kr(0.01) * drift1 * (6/1200)) + (LFNoise2.kr(3.1) * spread1 * (3/1200));
            var d_sig2 = (LFNoise2.kr(0.012) * drift2 * (6/1200)) + (LFNoise2.kr(3.4) * spread2 * (3/1200));
            var d_sig3 = (LFNoise2.kr(0.008) * drift3 * (6/1200)) + (LFNoise2.kr(2.9) * spread3 * (3/1200));
            var d_sig4 = (LFNoise2.kr(0.011) * drift4 * (6/1200)) + (LFNoise2.kr(3.2) * spread4 * (3/1200));
            
            var scale_map =[
                NamedControl.kr(\scale_map_0, 0), NamedControl.kr(\scale_map_1, 1),
                NamedControl.kr(\scale_map_2, 2), NamedControl.kr(\scale_map_3, 3),
                NamedControl.kr(\scale_map_4, 4), NamedControl.kr(\scale_map_5, 5),
                NamedControl.kr(\scale_map_6, 6), NamedControl.kr(\scale_map_7, 7),
                NamedControl.kr(\scale_map_8, 8), NamedControl.kr(\scale_map_9, 9),
                NamedControl.kr(\scale_map_10, 10), NamedControl.kr(\scale_map_11, 11)
            ];

            var mk_osc = { |f, s| 
                var noise = PinkNoise.ar;
                var phase = Phasor.ar(0, f.clip(20, 20000) * SampleDur.ir, 0, 1) + (noise * 0.15);
                var blurred_saw = (phase.wrap(0, 1) * 2) - 1;
                var tri = LFTri.ar(f.clip(20, 20000));
                var pul = Pulse.ar(f.clip(20, 20000), 0.5);
                var sin = SinOsc.ar(f.clip(20, 20000));
                SelectX.ar(s.clip(0,4),[noise, blurred_saw, tri, pul, sin]) 
            };
            
            var mk_vactrol = { |g, t| 
                var arp_env = Decay2.kr(Trig.kr(t, 0.01), 0.005, 0.2);
                var combined = (g + arp_env).clip(0, 1);
                LagUD.kr(combined, 0.01, 0.2) 
            };

            var calc_mod = { |dest_name, arp_val|
                (lfo1 * NamedControl.kr(("mod_lfo1_" ++ dest_name).asSymbol, 0)) +
                (lfo2 * NamedControl.kr(("mod_lfo2_" ++ dest_name).asSymbol, 0)) +
                (chaos_sig * NamedControl.kr(("mod_chaos_" ++ dest_name).asSymbol, 0)) +
                (outline_sig * NamedControl.kr(("mod_outline_" ++ dest_name).asSymbol, 0)) +
                (arp_val * NamedControl.kr(("mod_arp_" ++ dest_name).asSymbol, 0));
            };
            
            var calc_mod_pitch = { |dest_name, arp_val|
                var raw_lfo1 = lfo1 * NamedControl.kr(("mod_lfo1_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_lfo2 = lfo2 * NamedControl.kr(("mod_lfo2_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_chaos = chaos_sig * NamedControl.kr(("mod_chaos_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_outline = outline_sig * NamedControl.kr(("mod_outline_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_arp = arp_val * NamedControl.kr(("mod_arp_" ++ dest_name).asSymbol, 0) * 24.0;
                
                var quantize_fn = { |raw|
                    var rounded = raw.round;
                    var oct = (rounded / 12).floor;
                    var pc = rounded % 12;
                    (oct * 12) + Select.kr(pc, scale_map);
                };
                
                var q_lfo1 = Select.kr(NamedControl.kr(("quant_lfo1_" ++ dest_name).asSymbol, 1),[raw_lfo1, quantize_fn.(raw_lfo1)]);
                var q_lfo2 = Select.kr(NamedControl.kr(("quant_lfo2_" ++ dest_name).asSymbol, 1),[raw_lfo2, quantize_fn.(raw_lfo2)]);
                var q_chaos = Select.kr(NamedControl.kr(("quant_chaos_" ++ dest_name).asSymbol, 1),[raw_chaos, quantize_fn.(raw_chaos)]);
                var q_outline = Select.kr(NamedControl.kr(("quant_outline_" ++ dest_name).asSymbol, 1),[raw_outline, quantize_fn.(raw_outline)]);
                var q_arp = Select.kr(NamedControl.kr(("quant_arp_" ++ dest_name).asSymbol, 1),[raw_arp, quantize_fn.(raw_arp)]);
                
                (q_lfo1 + q_lfo2 + q_chaos + q_outline + q_arp) / 12.0;
            };

            s_freq1 = Lag.kr(freq1, lag); s_freq2 = Lag.kr(freq2, lag);
            s_freq3 = Lag.kr(freq3, lag); s_freq4 = Lag.kr(freq4, lag);
            s_vol1 = Lag.kr(vol1, lag);   s_vol2 = Lag.kr(vol2, lag);
            s_vol3 = Lag.kr(vol3, lag);   s_vol4 = Lag.kr(vol4, lag);
            s_filt1 = Lag.kr(filt1_cutoff, lag); s_filt2 = Lag.kr(filt2_cutoff, lag);

            lfo1 = SelectX.kr(lfo1_shape * 3,[
                LFPulse.kr(lfo1_rate, 0, 0.5), 
                (LFSaw.kr(lfo1_rate, 0) + 1) * 0.5, 
                (LFTri.kr(lfo1_rate, 0) + 1) * 0.5, 
                (SinOsc.kr(lfo1_rate, 0) + 1) * 0.5
            ]) * lfo1_depth;
            
            lfo2 = SelectX.kr(lfo2_shape * 3,[
                LFPulse.kr(lfo2_rate, 0, 0.5), 
                (LFSaw.kr(lfo2_rate, 0) + 1) * 0.5, 
                (LFTri.kr(lfo2_rate, 0) + 1) * 0.5, 
                (SinOsc.kr(lfo2_rate, 0) + 1) * 0.5
            ]) * lfo2_depth;
            
            rungler_clk = Impulse.kr(chaos_rate * 4);
            rungler_val = Latch.kr(WhiteNoise.kr, rungler_clk); 
            chaos_sig = Slew.kr(rungler_val, chaos_slew * 10, chaos_slew * 10) * chaos_amp;

            env_int = LagUD.kr((gate1+gate2+gate3+gate4).clip(0,1), 0.01, 0.5);
            env_ext = Amplitude.kr(LeakDC.ar(SoundIn.ar(0))); 
            outline_sig = Select.kr(outline_source,[env_int, env_ext]) * outline_gain;

            m_pitch1 = calc_mod_pitch.("pitch1", arp_cv1);
            m_pitch2 = calc_mod_pitch.("pitch2", arp_cv2);
            m_pitch3 = calc_mod_pitch.("pitch3", arp_cv3);
            m_pitch4 = calc_mod_pitch.("pitch4", arp_cv4);

            m_amp1 = calc_mod.("amp1", arp_cv1); m_amp2 = calc_mod.("amp2", arp_cv2);
            m_amp3 = calc_mod.("amp3", arp_cv3); m_amp4 = calc_mod.("amp4", arp_cv4);
            m_shape1 = calc_mod.("shape1", arp_cv1); m_shape2 = calc_mod.("shape2", arp_cv2);
            m_shape3 = calc_mod.("shape3", arp_cv3); m_shape4 = calc_mod.("shape4", arp_cv4);
            
            m_filt1 = calc_mod.("filt1", arp_cv1) * 5000; 
            m_filt2 = calc_mod.("filt2", arp_cv1) * 5000;
            
            m_delay_t = calc_mod.("delay_time", arp_cv1) * 0.1; 
            m_delay_f = calc_mod.("delay_fb", arp_cv1);

            vca1 = (s_vol1.squared + m_amp1).clip(0, 1);
            vca2 = (s_vol2.squared + m_amp2).clip(0, 1);
            vca3 = (s_vol3.squared + m_amp3).clip(0, 1);
            vca4 = (s_vol4.squared + m_amp4).clip(0, 1);

            o1 = mk_osc.(s_freq1 * (2.pow(m_pitch1 + d_sig1)), (shape1 + (m_shape1*4)).clip(0,4)) * vca1 * mk_vactrol.(gate1, t_arp1);
            o2 = mk_osc.(s_freq2 * (2.pow(m_pitch2 + d_sig2)), (shape2 + (m_shape2*4)).clip(0,4)) * vca2 * mk_vactrol.(gate2, t_arp2);
            o3 = mk_osc.(s_freq3 * (2.pow(m_pitch3 + d_sig3)), (shape3 + (m_shape3*4)).clip(0,4)) * vca3 * mk_vactrol.(gate3, t_arp3);
            o4 = mk_osc.(s_freq4 * (2.pow(m_pitch4 + d_sig4)), (shape4 + (m_shape4*4)).clip(0,4)) * vca4 * mk_vactrol.(gate4, t_arp4);

            sig_mix = (Pan2.ar(o1, pan1.clip(-1,1)) + Pan2.ar(o2, pan2.clip(-1,1)) + Pan2.ar(o3, pan3.clip(-1,1)) + Pan2.ar(o4, pan4.clip(-1,1))) * 0.125;

            sig_filt1 = DFM1.ar(sig_mix, (s_filt1 + m_filt1).clip(20, 18000), filt1_res.clip(0, 1.2), 1.0 + (filt1_drive * 3), filt1_type, 0.0003);
            sig_filt2 = DFM1.ar(sig_filt1, (s_filt2 + m_filt2).clip(20, 18000), filt2_res.clip(0, 1.2), 1.0 + (filt2_drive * 3), filt2_type, 0.0003);
            
            sig_pre = LeakDC.ar(sig_filt2); 

            hiss = PinkNoise.ar * system_dirt.pow(0.75) * 0.03;
            hum = SinOsc.ar([50, 50]) * system_dirt.pow(3) * 0.015;
            dust_sig = Decay2.ar(Dust.ar([dust_dens, dust_dens]), 0.001, 0.01) * PinkNoise.ar * system_dirt;
            dirt_sig = hiss + hum + dust_sig;

            // --- FxTape Integration ---
            time_kr = Lag.kr(fx_tape_time, 0.1);
            fb_kr = Lag.kr(fx_tape_feedback, 0.1);
            wf_kr = Lag.kr(fx_tape_wow_flutter, 0.1);
            ero_kr = Lag.kr(fx_tape_erosion, 0.1);
            drive_kr = Lag.kr(fx_tape_drive, 0.1);
            tone_kr = fx_tape_tone;

            local_in = LocalIn.ar(1);
            local_in = local_in * (1.0 - Trig.kr(clear_trig, 0.05));
            
            tape_in = (((sig_pre[0] + sig_pre[1]) * 0.5) + dirt_sig[0]) + (local_in * (fb_kr + m_delay_f).clip(0.0, 1.2));

            shared_wow = OnePole.kr(LFNoise2.kr(Rand(0.5, 2.0)) * wf_kr * 0.005, 0.95);
            shared_flutter = LFNoise1.kr(15) * wf_kr * 0.0005;
            shared_mod = shared_wow + shared_flutter;

            shared_dust_trig = Dust.kr(ero_kr * 15);
            shared_dropout_env = Decay.kr(shared_dust_trig, 0.1);

            dt_mono = (time_kr + m_delay_t + shared_mod).clip(0.01, 2.0);
            tape_del_mono = DelayC.ar(tape_in, 2.0, dt_mono);

            sat_mono = (tape_del_mono * drive_kr).tanh;

            ero_lpf_freq = LinExp.kr(ero_kr, 0.0, 1.0, 20000, 9000);
            ero_bass_cut = LinLin.kr(ero_kr, 0.0, 1.0, 0.0, -14.0);

            filt_mono = LPF.ar(sat_mono, ero_lpf_freq);
            filt_mono = BLowShelf.ar(filt_mono, 120, 1.0, ero_bass_cut);

            tone_freq = Select.kr((tone_kr - 1).round,[15000, 8000, 4000, 1600]);
            tone_filt_mono = LPF.ar(filt_mono, tone_freq);

            final_mono = tone_filt_mono * (1.0 - (shared_dropout_env * ero_kr).clip(0.0, 0.9));

            LocalOut.ar(final_mono);

            skew_lfo = LFNoise2.kr(0.1).range(-0.00075, 0.00075);
            skew_l = DelayC.ar(final_mono, 0.01, 0.00075 + skew_lfo);
            skew_r = DelayC.ar(final_mono, 0.01, 0.00075 - skew_lfo);

            cross_l = skew_l + (skew_r * 0.05);
            cross_r = skew_r + (skew_l * 0.05);

            eq_var_l = BPeakEQ.ar(cross_l, 98, 1.0, drive_kr * 3.0);
            eq_var_r = BPeakEQ.ar(cross_r, 101, 1.1, drive_kr * 2.98);

            tape_sig_l = LeakDC.ar(eq_var_l);
            tape_sig_r = LeakDC.ar(eq_var_r);

            // --- FxBlossom Integration ---
            decay_kr = Lag.kr(fx_blossom_decay, 0.1);
            bloom_kr = Lag.kr(fx_blossom_bloom, 0.1);
            damp_kr = Lag.kr(fx_blossom_damp, 0.1);
            predelay_kr = Lag.kr(fx_blossom_predelay, 0.1);
            mod_rate_kr = Lag.kr(fx_blossom_mod_rate, 0.1);
            mod_depth_kr = Lag.kr(fx_blossom_mod_depth, 0.1);

            rev_in = DelayN.ar([tape_sig_l, tape_sig_r], 1.0, predelay_kr) * 0.1;

            lfo_l = LFNoise2.kr(mod_rate_kr) * mod_depth_kr;
            lfo_r = LFNoise2.kr(mod_rate_kr * 1.1618) * mod_depth_kr;

            combs_l = prime_combs_l.collect { |time| CombC.ar(rev_in[0], 0.1, time + lfo_l, decay_kr) }.sum;
            combs_r = prime_combs_r.collect { |time| CombC.ar(rev_in[1], 0.1, time + lfo_r, decay_kr) }.sum;

            cross_l_rev = HPF.ar(combs_l + (combs_r * 0.2), 60);
            cross_r_rev = HPF.ar(combs_r + (combs_l * 0.2), 60);

            ap_l = cross_l_rev;
            ap_r = cross_r_rev;
            
            2.do { |i|
                ap_l = AllpassN.ar(ap_l, 0.05, prime_ap_l[i], bloom_kr * 2.0);
                ap_r = AllpassN.ar(ap_r, 0.05, prime_ap_r[i], bloom_kr * 2.0);
            };

            rev_filt_l = LPF.ar(ap_l, damp_kr);
            rev_filt_r = LPF.ar(ap_r, damp_kr);

            rev_out_l = ((LeakDC.ar(rev_filt_l) * 0.05).tanh * 3.6).softclip;
            rev_out_r = ((LeakDC.ar(rev_filt_r) * 0.05).tanh * 3.6).softclip;
            
            effects_out = (sig_pre * (1-delay_send)) + ([tape_sig_l, tape_sig_r] * delay_send);
            effects_out = (effects_out * (1-reverb_mix)) + ([rev_out_l, rev_out_r] * reverb_mix);
            
            sig_post = Limiter.ar(effects_out, 0.98);

            Out.ar(out, sig_post);

            osc_trig = Impulse.kr(15);
            amp_l = Amplitude.kr(sig_post[0]);
            amp_r = Amplitude.kr(sig_post[1]);
            SendReply.kr(osc_trig, '/ltra/visuals',[amp_l, amp_r, lfo1, lfo2, chaos_sig, outline_sig]);

        }).add;

        context.server.sync;
        synth = Synth.new(\ltra_core,[\out, context.out_b], context.xg);
        
        osc_bridge = OSCFunc({ |msg| NetAddr("127.0.0.1", 10111).sendMsg("/ltra/visuals", *msg.drop(3)); }, '/ltra/visuals', context.server.addr).fix;
        
        this.addCommand("set_engine_param", "sf", { arg msg; synth.set(msg[1].asSymbol, msg[2]); });
        this.addCommand("clear_delay", "", { synth.set(\clear_trig, 1); });
        
        this.addCommand("query_config", "", { NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", 0); });
        NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", 0);
    }
    free { synth.free; osc_bridge.free; }
}
