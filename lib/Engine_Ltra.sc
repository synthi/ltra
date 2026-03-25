// lib/Engine_Ltra.sc | v2.1.2
// FIX: Restored Lexical Closure Topology, MPE Clamping, Frame Error Eradicated

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
                glide1=0.001, glide2=0.001, glide3=0.001, glide4=0.001,
                gate1=0, gate2=0, gate3=0, gate4=0,
                env_atk1=0.01, env_atk2=0.01, env_atk3=0.01, env_atk4=0.01,
                env_rel1=0.2, env_rel2=0.2, env_rel3=0.2, env_rel4=0.2,
                
                midi_note1=60, midi_note2=60, midi_note3=60, midi_note4=60,
                midi_vel1=64, midi_vel2=64, midi_vel3=64, midi_vel4=64,
                vel_amt1=0, vel_amt2=0, vel_amt3=0, vel_amt4=0,
                vel_atk1=0, vel_atk2=0, vel_atk3=0, vel_atk4=0,
                vel_shp1=0, vel_shp2=0, vel_shp3=0, vel_shp4=0,
                
                mod_wheel=0, mw_filt2=0, mw_delay_f=0,
                pitch_bend=8192, bend_range=2,
                
                mpe_bend1=8192, mpe_bend2=8192, mpe_bend3=8192, mpe_bend4=8192, mpe_bend_range=48,
                slide1=0, slide2=0, slide3=0, slide4=0,
                slide_vol1=0, slide_vol2=0, slide_vol3=0, slide_vol4=0,
                slide_shp1=0, slide_shp2=0, slide_shp3=0, slide_shp4=0,
                press1=0, press2=0, press3=0, press4=0,
                press_vol1=0, press_vol2=0, press_vol3=0, press_vol4=0,
                press_shp1=0, press_shp2=0, press_shp3=0, press_shp4=0,
                
                arp_cv1=0, arp_cv2=0, arp_cv3=0, arp_cv4=0,
                
                mod1_lfo_rate=0.5, mod1_lfo_shape=0, mod1_depth=1,
                mod1_chaos_rate=0.5, mod1_chaos_slew=0.1, mod1_mix=0.0,
                mod2_lfo_rate=0.5, mod2_lfo_shape=0, mod2_depth=1,
                mod2_chaos_rate=0.5, mod2_chaos_slew=0.1, mod2_mix=0.0,
                mod3_lfo_rate=0.5, mod3_lfo_shape=0, mod3_depth=1,
                mod3_chaos_rate=0.5, mod3_chaos_slew=0.1, mod3_mix=0.0,
                
                outline_source=0, outline_gain=1.0,
                filt1_cutoff=32, filt2_cutoff=14200, 
                filt1_res=0, filt2_res=0,
                filt1_type=1, filt2_type=0, 
                filt1_drive=0, filt2_drive=0, 
                
                tapecho_time=0.3, tapecho_feedback=0.4, tapecho_wow_flutter=0.1,
                tapecho_erosion=0.0, tapecho_drive=1.0, tapecho_filter=8000, delay_send=0.5,
                
                blossomverb_decay=4.75, blossomverb_bloom=1.80, blossomverb_damp=3500,
                blossomverb_predelay=0.110, blossomverb_mod_rate=0.300, blossomverb_mod_depth=0.002, reverb_mix=0.0,
                
                system_dirt=0, dust_dens=0, 
                clear_trig=0, t_reset=0;

            // ==========================================
            // PHASE 1: LITERALS & FUNCTIONS (IMMEDIATE INIT)
            // ==========================================
            var prime_combs_l = #[0.031229, 0.037270, 0.043979, 0.050354, 0.057270, 0.064770];
            var prime_combs_r = #[0.031479, 0.037729, 0.044354, 0.050479, 0.057354, 0.064979];
            var prime_ap_l = #[0.011270, 0.031729];
            var prime_ap_r = #[0.011604, 0.031895];
            
            var scale_map =[
                NamedControl.kr(\scale_map_0, 0), NamedControl.kr(\scale_map_1, 1),
                NamedControl.kr(\scale_map_2, 2), NamedControl.kr(\scale_map_3, 3),
                NamedControl.kr(\scale_map_4, 4), NamedControl.kr(\scale_map_5, 5),
                NamedControl.kr(\scale_map_6, 6), NamedControl.kr(\scale_map_7, 7),
                NamedControl.kr(\scale_map_8, 8), NamedControl.kr(\scale_map_9, 9),
                NamedControl.kr(\scale_map_10, 10), NamedControl.kr(\scale_map_11, 11)
            ];

            var mk_osc = { |f, s| 
                var shape_idx = s.clip(0, 6);
                var safe_f = f.clip(20, 20000);
                var sig0 = PinkNoise.ar;
                var core_saw = SawDPW.ar(safe_f);
                var pm_amt = SelectX.kr(shape_idx.clip(1, 2) - 1, [0.15, 0.0]);
                var pm_mod = LPF.ar(PinkNoise.ar, 10000) * pm_amt * 0.015;
                var sig1 = DelayC.ar(core_saw, 0.04, 0.02 + pm_mod);
                var sig2 = core_saw;
                var sqr_raw = core_saw - DelayC.ar(core_saw, 0.1, 0.5 / safe_f);
                var sig5 = LeakDC.ar(sqr_raw) * 0.5;
                var tri_raw = Integrator.ar(sig5, 0.999) * (4.0 * safe_f / SampleRate.ir);
                var sig3 = LeakDC.ar(tri_raw);
                var sig4 = (sig3.clip(-1.0, 1.0) * (pi/2)).sin;
                var pulse_delay = (0.02 / safe_f).max(SampleDur.ir);
                var pulse_raw = core_saw - DelayC.ar(core_saw, 0.1, pulse_delay);
                var sig6 = LeakDC.ar(pulse_raw) * 0.5 * 1.5;
                SelectX.ar(shape_idx,[sig0, sig1, sig2, sig3, sig4, sig5, sig6]);
            };

            // ==========================================
            // PHASE 2: AUDIO & CONTROL VARIABLES
            // ==========================================
            var mod1_lfo, mod1_chaos, mod1_sig;
            var mod2_lfo, mod2_chaos, mod2_sig;
            var mod3_lfo, mod3_chaos, mod3_sig;
            var outline_sig, env_int, env_ext;
            var m_pitch1, m_pitch2, m_pitch3, m_pitch4;
            var m_amp1, m_amp2, m_amp3, m_amp4;
            var m_shape1, m_shape2, m_shape3, m_shape4;
            var m_filt1, m_filt2, m_delay_t, m_delay_f;
            var o1, o2, o3, o4, sig_mix;
            var sig_filt1, sig_filt2, sig_pre;
            var dirt_sig, hiss, hum, dust_sig;
            var effects_out, sig_post;
            var osc_trig;
            var s_freq1, s_freq2, s_freq3, s_freq4;
            var s_vol1, s_vol2, s_vol3, s_vol4;
            var s_filt1, s_filt2;
            var vca1, vca2, vca3, vca4;
            var env1, env2, env3, env4;
            var bend_norm, bend_offset;
            var mpe_bend_off1, mpe_bend_off2, mpe_bend_off3, mpe_bend_off4;
            var midi_off1, midi_off2, midi_off3, midi_off4;
            var vel_bip1, vel_bip2, vel_bip3, vel_bip4;
            var mw_norm;
            var slide_n1, slide_n2, slide_n3, slide_n4;
            var press_n1, press_n2, press_n3, press_n4;
            var final_shape1, final_shape2, final_shape3, final_shape4;
            var final_atk1, final_atk2, final_atk3, final_atk4;
            var tape_in, local_in, shared_wow, shared_flutter, shared_mod;
            var shared_dust_trig, shared_dropout_env, dt_mono, tape_del_mono;
            var sat_mono, ero_lpf_freq, ero_bass_cut, filt_mono, tone_filt_mono, final_mono;
            var skew_lfo, skew_l, skew_r, cross_l, cross_r, eq_var_l, eq_var_r;
            var tape_sig_l, tape_sig_r;
            var time_kr, fb_kr, wf_kr, ero_kr, drive_kr, filter_kr;
            var rev_in, lfo_l, lfo_r, combs_l, combs_r, cross_l_rev, cross_r_rev;
            var ap_l, ap_r, rev_filt_l, rev_filt_r, rev_out_l, rev_out_r;
            var decay_kr, bloom_kr, damp_kr, predelay_kr, mod_rate_kr, mod_depth_kr;
            var d_sig1, d_sig2, d_sig3, d_sig4;
            
            // Functions that capture variables by reference
            var calc_mod = { |dest_name, arp_val|
                (mod1_sig * NamedControl.kr(("mod_mod1_" ++ dest_name).asSymbol, 0)) +
                (mod2_sig * NamedControl.kr(("mod_mod2_" ++ dest_name).asSymbol, 0)) +
                (mod3_sig * NamedControl.kr(("mod_mod3_" ++ dest_name).asSymbol, 0)) +
                (outline_sig * NamedControl.kr(("mod_outline_" ++ dest_name).asSymbol, 0)) +
                (arp_val * NamedControl.kr(("mod_arp_" ++ dest_name).asSymbol, 0));
            };
            
            var calc_mod_pitch = { |dest_name, arp_val|
                var raw_mod1 = mod1_sig * NamedControl.kr(("mod_mod1_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_mod2 = mod2_sig * NamedControl.kr(("mod_mod2_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_mod3 = mod3_sig * NamedControl.kr(("mod_mod3_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_outline = outline_sig * NamedControl.kr(("mod_outline_" ++ dest_name).asSymbol, 0) * 24.0;
                var raw_arp = arp_val * NamedControl.kr(("mod_arp_" ++ dest_name).asSymbol, 0) * 24.0;
                var quantize_fn = { |raw|
                    var rounded = raw.round;
                    var oct = (rounded / 12).floor;
                    var pc = rounded % 12;
                    (oct * 12) + Select.kr(pc, scale_map);
                };
                var q_mod1 = Select.kr(NamedControl.kr(("quant_mod1_" ++ dest_name).asSymbol, 1),[raw_mod1, quantize_fn.(raw_mod1)]);
                var q_mod2 = Select.kr(NamedControl.kr(("quant_mod2_" ++ dest_name).asSymbol, 1),[raw_mod2, quantize_fn.(raw_mod2)]);
                var q_mod3 = Select.kr(NamedControl.kr(("quant_mod3_" ++ dest_name).asSymbol, 1),[raw_mod3, quantize_fn.(raw_mod3)]);
                var q_outline = Select.kr(NamedControl.kr(("quant_outline_" ++ dest_name).asSymbol, 1),[raw_outline, quantize_fn.(raw_outline)]);
                var q_arp = Select.kr(NamedControl.kr(("quant_arp_" ++ dest_name).asSymbol, 1),[raw_arp, quantize_fn.(raw_arp)]);
                (q_mod1 + q_mod2 + q_mod3 + q_outline + q_arp) / 12.0;
            };

            // ==========================================
            // PHASE 3: SIGNAL FLOW
            // ==========================================
            d_sig1 = (LFNoise2.kr(0.01) * drift1 * (6/1200)) + (LFNoise2.kr(3.1) * spread1 * (3/1200));
            d_sig2 = (LFNoise2.kr(0.012) * drift2 * (6/1200)) + (LFNoise2.kr(3.4) * spread2 * (3/1200));
            d_sig3 = (LFNoise2.kr(0.008) * drift3 * (6/1200)) + (LFNoise2.kr(2.9) * spread3 * (3/1200));
            d_sig4 = (LFNoise2.kr(0.011) * drift4 * (6/1200)) + (LFNoise2.kr(3.2) * spread4 * (3/1200));

            s_freq1 = Lag.kr(freq1, glide1); s_freq2 = Lag.kr(freq2, glide2);
            s_freq3 = Lag.kr(freq3, glide3); s_freq4 = Lag.kr(freq4, glide4);
            
            s_vol1 = Lag.kr(vol1, 0.05);   s_vol2 = Lag.kr(vol2, 0.05);
            s_vol3 = Lag.kr(vol3, 0.05);   s_vol4 = Lag.kr(vol4, 0.05);
            s_filt1 = Lag.kr(filt1_cutoff, 0.05); s_filt2 = Lag.kr(filt2_cutoff, 0.05);

            mod1_lfo = SelectX.kr(mod1_lfo_shape * 3,[ LFPulse.kr(mod1_lfo_rate, 0, 0.5), (LFSaw.kr(mod1_lfo_rate, 0) + 1) * 0.5, (LFTri.kr(mod1_lfo_rate, 0) + 1) * 0.5, (SinOsc.kr(mod1_lfo_rate, 0) + 1) * 0.5 ]);
            mod1_chaos = Slew.kr(Latch.kr(WhiteNoise.kr.range(0, 1), Impulse.kr(mod1_chaos_rate * 4)), mod1_chaos_slew * 10, mod1_chaos_slew * 10);
            mod1_sig = SelectX.kr(mod1_mix,[mod1_lfo, mod1_chaos]) * mod1_depth;

            mod2_lfo = SelectX.kr(mod2_lfo_shape * 3,[ LFPulse.kr(mod2_lfo_rate, 0, 0.5), (LFSaw.kr(mod2_lfo_rate, 0) + 1) * 0.5, (LFTri.kr(mod2_lfo_rate, 0) + 1) * 0.5, (SinOsc.kr(mod2_lfo_rate, 0) + 1) * 0.5 ]);
            mod2_chaos = Slew.kr(Latch.kr(WhiteNoise.kr.range(0, 1), Impulse.kr(mod2_chaos_rate * 4)), mod2_chaos_slew * 10, mod2_chaos_slew * 10);
            mod2_sig = SelectX.kr(mod2_mix,[mod2_lfo, mod2_chaos]) * mod2_depth;

            mod3_lfo = SelectX.kr(mod3_lfo_shape * 3,[ LFPulse.kr(mod3_lfo_rate, 0, 0.5), (LFSaw.kr(mod3_lfo_rate, 0) + 1) * 0.5, (LFTri.kr(mod3_lfo_rate, 0) + 1) * 0.5, (SinOsc.kr(mod3_lfo_rate, 0) + 1) * 0.5 ]);
            mod3_chaos = Slew.kr(Latch.kr(WhiteNoise.kr.range(0, 1), Impulse.kr(mod3_chaos_rate * 4)), mod3_chaos_slew * 10, mod3_chaos_slew * 10);
            mod3_sig = SelectX.kr(mod3_mix,[mod3_lfo, mod3_chaos]) * mod3_depth;

            env_int = LagUD.kr((gate1+gate2+gate3+gate4).clip(0,1), 0.01, 0.5);
            env_ext = Amplitude.kr(LeakDC.ar(SoundIn.ar(0))); 
            outline_sig = Select.kr(outline_source,[env_int, env_ext]) * outline_gain;

            m_pitch1 = calc_mod_pitch.("pitch1", arp_cv1); m_pitch2 = calc_mod_pitch.("pitch2", arp_cv2);
            m_pitch3 = calc_mod_pitch.("pitch3", arp_cv3); m_pitch4 = calc_mod_pitch.("pitch4", arp_cv4);

            m_amp1 = calc_mod.("amp1", arp_cv1); m_amp2 = calc_mod.("amp2", arp_cv2);
            m_amp3 = calc_mod.("amp3", arp_cv3); m_amp4 = calc_mod.("amp4", arp_cv4);
            m_shape1 = calc_mod.("shape1", arp_cv1); m_shape2 = calc_mod.("shape2", arp_cv2);
            m_shape3 = calc_mod.("shape3", arp_cv3); m_shape4 = calc_mod.("shape4", arp_cv4);
            
            mw_norm = mod_wheel / 127.0; 
            m_filt1 = calc_mod.("filt1", arp_cv1) * 5000; 
            m_filt2 = calc_mod.("filt2", arp_cv1) * 5000 + (mw_norm * mw_filt2 * 5000);
            
            m_delay_t = calc_mod.("tapecho_time", arp_cv1) * 0.1; 
            m_delay_f = calc_mod.("tapecho_feedback", arp_cv1) + (mw_norm * mw_delay_f);

            bend_norm = (pitch_bend - 8192) / 8192.0;
            bend_offset = bend_norm * bend_range / 12.0;
            
            mpe_bend_off1 = ((mpe_bend1 - 8192) / 8192.0) * mpe_bend_range / 12.0;
            mpe_bend_off2 = ((mpe_bend2 - 8192) / 8192.0) * mpe_bend_range / 12.0;
            mpe_bend_off3 = ((mpe_bend3 - 8192) / 8192.0) * mpe_bend_range / 12.0;
            mpe_bend_off4 = ((mpe_bend4 - 8192) / 8192.0) * mpe_bend_range / 12.0;
            
            midi_off1 = (midi_note1 - 60) / 12.0; midi_off2 = (midi_note2 - 60) / 12.0;
            midi_off3 = (midi_note3 - 60) / 12.0; midi_off4 = (midi_note4 - 60) / 12.0;
            
            vel_bip1 = (midi_vel1 - 64) / 63.0; vel_bip2 = (midi_vel2 - 64) / 63.0;
            vel_bip3 = (midi_vel3 - 64) / 63.0; vel_bip4 = (midi_vel4 - 64) / 63.0;
            
            slide_n1 = slide1 / 127.0; slide_n2 = slide2 / 127.0;
            slide_n3 = slide3 / 127.0; slide_n4 = slide4 / 127.0;
            
            press_n1 = press1 / 127.0; press_n2 = press2 / 127.0;
            press_n3 = press3 / 127.0; press_n4 = press4 / 127.0;

            vca1 = (s_vol1.squared + m_amp1 + (vel_bip1 * vel_amt1 * s_vol1.squared) + (slide_n1 * slide_vol1) + (press_n1 * press_vol1)).clip(0, 1);
            vca2 = (s_vol2.squared + m_amp2 + (vel_bip2 * vel_amt2 * s_vol2.squared) + (slide_n2 * slide_vol2) + (press_n2 * press_vol2)).clip(0, 1);
            vca3 = (s_vol3.squared + m_amp3 + (vel_bip3 * vel_amt3 * s_vol3.squared) + (slide_n3 * slide_vol3) + (press_n3 * press_vol3)).clip(0, 1);
            vca4 = (s_vol4.squared + m_amp4 + (vel_bip4 * vel_amt4 * s_vol4.squared) + (slide_n4 * slide_vol4) + (press_n4 * press_vol4)).clip(0, 1);
            
            final_shape1 = (shape1 + (m_shape1*6) + (vel_bip1 * vel_shp1 * 6) + (slide_n1 * slide_shp1 * 6) + (press_n1 * press_shp1 * 6)).clip(0, 6);
            final_shape2 = (shape2 + (m_shape2*6) + (vel_bip2 * vel_shp2 * 6) + (slide_n2 * slide_shp2 * 6) + (press_n2 * press_shp2 * 6)).clip(0, 6);
            final_shape3 = (shape3 + (m_shape3*6) + (vel_bip3 * vel_shp3 * 6) + (slide_n3 * slide_shp3 * 6) + (press_n3 * press_shp3 * 6)).clip(0, 6);
            final_shape4 = (shape4 + (m_shape4*6) + (vel_bip4 * vel_shp4 * 6) + (slide_n4 * slide_shp4 * 6) + (press_n4 * press_shp4 * 6)).clip(0, 6);

            final_atk1 = (env_atk1 + (vel_bip1 * vel_atk1 * 5.0)).clip(0.001, 10.0);
            final_atk2 = (env_atk2 + (vel_bip2 * vel_atk2 * 5.0)).clip(0.001, 10.0);
            final_atk3 = (env_atk3 + (vel_bip3 * vel_atk3 * 5.0)).clip(0.001, 10.0);
            final_atk4 = (env_atk4 + (vel_bip4 * vel_atk4 * 5.0)).clip(0.001, 10.0);

            env1 = EnvGen.kr(Env.asr(final_atk1, 1.0, env_rel1), gate1);
            env2 = EnvGen.kr(Env.asr(final_atk2, 1.0, env_rel2), gate2);
            env3 = EnvGen.kr(Env.asr(final_atk3, 1.0, env_rel3), gate3);
            env4 = EnvGen.kr(Env.asr(final_atk4, 1.0, env_rel4), gate4);

            o1 = mk_osc.(s_freq1 * (2.pow(m_pitch1 + d_sig1 + bend_offset + mpe_bend_off1 + midi_off1)), final_shape1) * vca1 * env1;
            o2 = mk_osc.(s_freq2 * (2.pow(m_pitch2 + d_sig2 + bend_offset + mpe_bend_off2 + midi_off2)), final_shape2) * vca2 * env2;
            o3 = mk_osc.(s_freq3 * (2.pow(m_pitch3 + d_sig3 + bend_offset + mpe_bend_off3 + midi_off3)), final_shape3) * vca3 * env3;
            o4 = mk_osc.(s_freq4 * (2.pow(m_pitch4 + d_sig4 + bend_offset + mpe_bend_off4 + midi_off4)), final_shape4) * vca4 * env4;

            sig_mix = (Pan2.ar(o1, pan1.clip(-1,1)) + Pan2.ar(o2, pan2.clip(-1,1)) + Pan2.ar(o3, pan3.clip(-1,1)) + Pan2.ar(o4, pan4.clip(-1,1))) * 0.125;

            sig_filt1 = DFM1.ar(sig_mix, (s_filt1 + m_filt1).clip(20, 18000), filt1_res.clip(0, 1.2), 1.0 + (filt1_drive * 3), filt1_type, 0.0003);
            sig_filt2 = DFM1.ar(sig_filt1, (s_filt2 + m_filt2).clip(20, 18000), filt2_res.clip(0, 1.2), 1.0 + (filt2_drive * 3), filt2_type, 0.0003);
            
            sig_pre = LeakDC.ar(sig_filt2); 

            hiss = PinkNoise.ar * system_dirt.pow(0.75) * 0.03;
            hum = SinOsc.ar([50, 50]) * system_dirt.pow(3) * 0.015;
            dust_sig = Decay2.ar(Dust.ar([dust_dens, dust_dens]), 0.001, 0.01) * PinkNoise.ar * system_dirt;
            dirt_sig = hiss + hum + dust_sig;

            time_kr = Lag.kr(tapecho_time, 0.1);
            fb_kr = Lag.kr(tapecho_feedback, 0.1);
            wf_kr = Lag.kr(tapecho_wow_flutter, 0.1);
            ero_kr = Lag.kr(tapecho_erosion, 0.1);
            drive_kr = Lag.kr(tapecho_drive, 0.1);
            filter_kr = Lag.kr(tapecho_filter, 0.1); 

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

            tone_filt_mono = LPF.ar(filt_mono, filter_kr.clip(20, 18000));

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

            decay_kr = Lag.kr(blossomverb_decay, 0.1);
            bloom_kr = Lag.kr(blossomverb_bloom, 0.1);
            damp_kr = Lag.kr(blossomverb_damp, 0.1);
            predelay_kr = Lag.kr(blossomverb_predelay, 0.1);
            mod_rate_kr = Lag.kr(blossomverb_mod_rate, 0.1);
            mod_depth_kr = Lag.kr(blossomverb_mod_depth, 0.1);

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

            rev_out_l = ((LeakDC.ar(rev_filt_l) * 0.05).tanh * 3.6).softclip * 4.0;
            rev_out_r = ((LeakDC.ar(rev_filt_r) * 0.05).tanh * 3.6).softclip * 4.0;
            
            effects_out = (sig_pre * (1-delay_send)) + ([tape_sig_l, tape_sig_r] * delay_send);
            effects_out = (effects_out * (1-reverb_mix)) + ([rev_out_l, rev_out_r] * reverb_mix);
            
            sig_post = Limiter.ar(effects_out, 0.98);

            Out.ar(out, sig_post);

            osc_trig = Impulse.kr(15);
            SendReply.kr(osc_trig, '/ltra/visuals',[mod1_sig, mod2_sig, mod3_sig, outline_sig]);

        }).add;

        context.server.sync;
        synth = Synth.new(\ltra_core,[\out, context.out_b], context.xg);
        
        osc_bridge = OSCFunc({ |msg| NetAddr("127.0.0.1", 10111).sendMsg("/ltra/visuals", *msg.drop(3)); }, '/ltra/visuals', context.server.addr).fix;
        
        this.addCommand("set_engine_param", "sf", { arg msg; synth.set(msg[1].asSymbol, msg[2]); });
        this.addCommand("clear_delay", "", { synth.set(\clear_trig, 1); });
        this.addCommand("ping", "", { NetAddr("127.0.0.1", 10111).sendMsg("/ltra/ready"); });
        
        this.addCommand("query_config", "", { NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", 0); });
        NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", 0);
    }
    free { synth.free; osc_bridge.free; }
}
