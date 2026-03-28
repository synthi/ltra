// lib/Engine_Ltra.sc | v2.3.1
// FIX: Dynamic Q for Tuned Noise, PM Index Recalibration, Psychoacoustic Gain Map

Engine_Ltra : CroneEngine {
    var <synth;
    var <osc_bridge;
    var <matrix_amts;
    var <matrix_quants;

    *new { arg context, doneCallback; ^super.new(context, doneCallback); }

    alloc {
        matrix_amts = Array.fill(5, { Array.fill(16, 0.0) });
        matrix_quants = Array.fill(5, { Array.fill(16, 1.0) });

        SynthDef(\ltra_core, {
            var out = \out.kr(0);
            
            var mod_wheel = \mod_wheel.kr(0);
            var mw_filt2 = \mw_filt2.kr(0);
            var mw_delay_f = \mw_delay_f.kr(0);
            var pitch_bend = \pitch_bend.kr(8192);
            var bend_range = \bend_range.kr(2);
            var mpe_bend_range = \mpe_bend_range.kr(48);
            
            var mpe_lag = \mpe_lag.kr(0.0);
            var vel_curve = \vel_curve.kr(0.0);
            var slide_curve = \slide_curve.kr(0.0);
            var press_curve = \press_curve.kr(0.0);
            
            var mod1_lfo_rate = \mod1_lfo_rate.kr(0.5);
            var mod1_lfo_shape = \mod1_lfo_shape.kr(0);
            var mod1_depth = \mod1_depth.kr(1);
            var mod1_chaos_rate = \mod1_chaos_rate.kr(0.5);
            var mod1_chaos_slew = \mod1_chaos_slew.kr(0.1);
            var mod1_mix = \mod1_mix.kr(0);
            
            var mod2_lfo_rate = \mod2_lfo_rate.kr(0.5);
            var mod2_lfo_shape = \mod2_lfo_shape.kr(0);
            var mod2_depth = \mod2_depth.kr(1);
            var mod2_chaos_rate = \mod2_chaos_rate.kr(0.5);
            var mod2_chaos_slew = \mod2_chaos_slew.kr(0.1);
            var mod2_mix = \mod2_mix.kr(0);
            
            var mod3_lfo_rate = \mod3_lfo_rate.kr(0.5);
            var mod3_lfo_shape = \mod3_lfo_shape.kr(0);
            var mod3_depth = \mod3_depth.kr(1);
            var mod3_chaos_rate = \mod3_chaos_rate.kr(0.5);
            var mod3_chaos_slew = \mod3_chaos_slew.kr(0.1);
            var mod3_mix = \mod3_mix.kr(0);
            
            var outline_source = \outline_source.kr(0);
            var outline_gain = \outline_gain.kr(1.0);
            
            var filt1_cutoff = \filt1_cutoff.kr(32);
            var filt2_cutoff = \filt2_cutoff.kr(14200);
            var filt1_res = \filt1_res.kr(0);
            var filt2_res = \filt2_res.kr(0);
            var filt1_type = \filt1_type.kr(1);
            var filt2_type = \filt2_type.kr(0);
            var filt1_drive = \filt1_drive.kr(0);
            var filt2_drive = \filt2_drive.kr(0);
            
            var tapecho_time = \tapecho_time.kr(0.3);
            var tapecho_feedback = \tapecho_feedback.kr(0.4);
            var tapecho_wow_flutter = \tapecho_wow_flutter.kr(0.1);
            var tapecho_erosion = \tapecho_erosion.kr(0.0);
            var tapecho_drive = \tapecho_drive.kr(1.0);
            var tapecho_filter = \tapecho_filter.kr(8000);
            var delay_send = \delay_send.kr(0.5);
            
            var blossomverb_decay = \blossomverb_decay.kr(4.75);
            var blossomverb_bloom = \blossomverb_bloom.kr(1.80);
            var blossomverb_damp = \blossomverb_damp.kr(3500);
            var blossomverb_predelay = \blossomverb_predelay.kr(0.110);
            var blossomverb_mod_rate = \blossomverb_mod_rate.kr(0.300);
            var blossomverb_mod_depth = \blossomverb_mod_depth.kr(0.002);
            var reverb_mix = \reverb_mix.kr(0.0);
            
            var system_dirt = \system_dirt.kr(0);
            var dust_dens = \dust_dens.kr(0);
            var clear_trig = \clear_trig.kr(0);
            
            var freqs = 8.collect { |i| NamedControl.kr("freq" ++ (i+1), 110) };
            var gates = 8.collect { |i| NamedControl.kr("gate" ++ (i+1), 0) };
            var midi_notes = 8.collect { |i| NamedControl.kr("midi_note" ++ (i+1), 60) };
            var midi_vels = 8.collect { |i| NamedControl.kr("midi_vel" ++ (i+1), 64) };
            var mpe_bends = 8.collect { |i| NamedControl.kr("mpe_bend" ++ (i+1), 8192) };
            var slides = 8.collect { |i| NamedControl.kr("slide" ++ (i+1), 0) };
            var presses = 8.collect { |i| NamedControl.kr("press" ++ (i+1), 0) };
            
            var shapes = 4.collect { |i| NamedControl.kr("shape" ++ (i+1), 2) };
            var vols = 4.collect { |i| NamedControl.kr("vol" ++ (i+1), 0) };
            var pans = 4.collect { |i| NamedControl.kr("pan" ++ (i+1), 0) };
            var drifts = 4.collect { |i| NamedControl.kr("drift" ++ (i+1), 0) };
            var spreads = 4.collect { |i| NamedControl.kr("spread" ++ (i+1), 0) };
            var glides = 4.collect { |i| NamedControl.kr("glide" ++ (i+1), 0.001) };
            var env_atks = 4.collect { |i| NamedControl.kr("env_atk" ++ (i+1), 0.01) };
            var env_rels = 4.collect { |i| NamedControl.kr("env_rel" ++ (i+1), 0.2) };
            var vel_amts = 4.collect { |i| NamedControl.kr("vel_amt" ++ (i+1), 0) };
            var vel_atks = 4.collect { |i| NamedControl.kr("vel_atk" ++ (i+1), 0) };
            var vel_shps = 4.collect { |i| NamedControl.kr("vel_shp" ++ (i+1), 0) };
            var slide_vols = 4.collect { |i| NamedControl.kr("slide_vol" ++ (i+1), 0) };
            var slide_shps = 4.collect { |i| NamedControl.kr("slide_shp" ++ (i+1), 0) };
            var press_vols = 4.collect { |i| NamedControl.kr("press_vol" ++ (i+1), 0) };
            var press_shps = 4.collect { |i| NamedControl.kr("press_shp" ++ (i+1), 0) };
            var arp_cvs = 4.collect { |i| NamedControl.kr("arp_cv" ++ (i+1), 0) };
            var mw_shps = 4.collect { |i| NamedControl.kr("mw_shp" ++ (i+1), 0) };
            var twin_enables = 4.collect { |i| NamedControl.kr("twin_enable" ++ (i+1), 0) };
            var midi_gates = 4.collect { |i| NamedControl.kr("midi_gate" ++ (i+1), 0) };

            var mod1_dest = \mod1_dest.kr(0!16);
            var mod2_dest = \mod2_dest.kr(0!16);
            var mod3_dest = \mod3_dest.kr(0!16);
            var outline_dest = \outline_dest.kr(0!16);
            var arp_dest = \arp_dest.kr(0!16);
            
            var mod1_quant = \mod1_quant.kr(1!16);
            var mod2_quant = \mod2_quant.kr(1!16);
            var mod3_quant = \mod3_quant.kr(1!16);
            var outline_quant = \outline_quant.kr(1!16);
            var arp_quant = \arp_quant.kr(1!16);

            var mod1_lfo, mod1_chaos, mod1_sig;
            var mod2_lfo, mod2_chaos, mod2_sig;
            var mod3_lfo, mod3_chaos, mod3_sig;
            var m1_shape_mod, m1_final_shape;
            var m2_shape_mod, m2_final_shape;
            var m3_shape_mod, m3_final_shape;
            
            var env_int, env_ext, outline_sig;
            var mw_norm, bend_norm, bend_offset;
            var m_filt1, m_filt2, m_delay_t, m_delay_f;
            var s_filt1, s_filt2;
            var sig_mix, sig_filt1, sig_filt2, sig_pre;
            var dirt_sig, hiss, hum, dust_sig;
            var tape_in, local_in, shared_wow, shared_flutter, shared_mod;
            var shared_dust_trig, shared_dropout_env, dt_mono, tape_del_mono;
            var sat_mono, ero_lpf_freq, ero_bass_cut, filt_mono, tone_filt_mono, final_mono;
            var skew_lfo, skew_l, skew_r, cross_l, cross_r, eq_var_l, eq_var_r;
            var tape_sig_l, tape_sig_r;
            var time_kr, fb_kr, wf_kr, ero_kr, drive_kr, filter_kr;
            var rev_in, lfo_l, lfo_r, combs_l, combs_r, cross_l_rev, cross_r_rev;
            var ap_l, ap_r, rev_filt_l, rev_filt_r, rev_out_l, rev_out_r;
            var decay_kr, bloom_kr, damp_kr, predelay_kr, mod_rate_kr, mod_depth_kr;
            var effects_out, sig_post, osc_trig;
            var scale_map, mk_osc, calc_mod, calc_mod_pitch;
            var voices_out;
            
            var prime_combs_l = #[0.031229, 0.037270, 0.043979, 0.050354, 0.057270, 0.064770];
            var prime_combs_r = #[0.031479, 0.037729, 0.044354, 0.050479, 0.057354, 0.064979];
            var prime_ap_l = #[0.011270, 0.031729];
            var prime_ap_r = #[0.011604, 0.031895];

            scale_map = 12.collect { |i| NamedControl.kr("scale_map_" ++ i, i) };

            // ==========================================
            // 11-STAGE CONTINUOUS MORPHING (0.0 to 10.0)
            // ==========================================
            mk_osc = { |f, s| 
                var shape_idx = s.clip(0, 10);
                var safe_f = f.clip(20, 20000);
                var core_saw = SawDPW.ar(safe_f);
                
                // Stage 0-1: Dust -> Pink Noise
                var density = shape_idx.clip(0, 1).linexp(0, 1, 4, 20000);
                var lpf_freq = shape_idx.clip(0, 1).linexp(0, 1, 400, 20000);
                var dust_env = Clip.ar(Decay.ar(Dust.ar(density), 0.05) * 10.0, 0.0, 1.0);
                var noise_src = LPF.ar(PinkNoise.ar * dust_env, lpf_freq);
                
                // Stage 1-2: Pink Noise -> Tuned Noise
                // MASTERING TEAM: Tweak the 0.007 value here for Tuned Noise resonance (lower = more sine-like, higher = more noisy)
                var tuned_rq = shape_idx.clip(1, 2).linexp(1, 2, 0.02, 0.007);
                var tuned_noise = Resonz.ar(noise_src, safe_f, tuned_rq) * (tuned_rq ** -0.5) * 0.5;
                var stage1_osc = XFade2.ar(noise_src, tuned_noise, (shape_idx - 1.0).clip(0, 1) * 2.0 - 1.0);
                
                // Stage 2-4: Tuned Noise -> Tuned Noised Saw -> Pure Saw
                // FIX: PM Index recalibrated to 0.05 max at shape 3.0
                var pm_index = (4.0 - shape_idx).clip(0, 1).lincurve(0, 1, 0.0, 0.05, 2);
                var pm_mod = LPF.ar(tuned_noise, 10000) * pm_index;
                var saw_pm = DelayC.ar(core_saw, 0.04, 0.02 + pm_mod);
                
                var carrier_mix = (shape_idx - 2.0).clip(0, 1);
                var base_osc = (stage1_osc * (1.0 - carrier_mix)) + (saw_pm * carrier_mix);
                
                // Stage 4-6: Saw -> Square -> Pulse 2.5%
                var sub_mix = (shape_idx - 4.0).clip(0, 1);
                var dc_narrow = (shape_idx - 5.0).clip(0, 1).lincurve(0, 1, 0.0, 0.475, 4);
                var dc_widen = (shape_idx - 7.0).clip(0, 0.5).lincurve(0, 0.5, 0.0, 0.475, -2); // Opens from 7.0 to 7.5
                var duty_cycle = 0.5 - dc_narrow + dc_widen;
                
                var delay_time = (duty_cycle / safe_f).max(SampleDur.ir);
                var pulse_raw = base_osc - (DelayC.ar(base_osc, 0.1, delay_time) * sub_mix);
                var pulse_dc = LeakDC.ar(pulse_raw) * 0.5;
                
                // Stage 6-7.5: Pulse -> Skewed Tri (7.0) -> Pure Tri (7.5)
                var int_mix = (shape_idx - 6.0).clip(0, 1);
                var tri_raw = Clip.ar(Integrator.ar(pulse_dc, 0.99), -10.0, 10.0) * (4.0 * safe_f / SampleRate.ir);
                var tri_dc = LeakDC.ar(tri_raw);
                var osc_stage3 = (pulse_dc * (1.0 - int_mix)) + (tri_dc * int_mix);
                
                // Stage 7.5-8: Pure Tri -> Sine
                var sine_mix = (shape_idx - 7.5).clip(0, 0.5) * 2.0;
                
                // Stage 8-10: Sine -> Buchla Folded -> Buchla Asym
                var fold_drive_actual = (shape_idx - 8.0).clip(0, 1).linexp(0, 1, 1.0, 12.0);
                var asym_offset = (shape_idx - 9.0).clip(0, 1).lincurve(0, 1, 0.0, 0.4, 2);
                
                var pure_sine = ((osc_stage3 + asym_offset) * 0.5pi).sin - asym_offset;
                var folded_sine = (pure_sine * fold_drive_actual).fold2(1.0);
                var mitigated_folded = LPF.ar(folded_sine, (safe_f * 24.0).clip(20, 19000));
                
                var final_osc = (osc_stage3 * (1.0 - sine_mix)) + (mitigated_folded * sine_mix);
                
                // FIX: Psychoacoustic Gain Map (dB Interpolation)
                var gain_db = SelectX.kr(shape_idx,[
                    9.5,   // 0.0 Dust
                    8.0,   // 1.0 Pink Noise
                    3.5,   // 2.0 Tuned Noise
                    0.0,   // 3.0 Tuned Noised Saw
                    0.0,   // 4.0 Pure Saw
                    -2.0,  // 5.0 Square (Attenuated RMS)
                    2.5,   // 6.0 Pulse 2.5% (Tamed piercing highs)
                    8.0,   // 7.0 Skewed Tri
                    0.0,   // 8.0 Pure Sine (7.5 Pure Tri is interpolated to +4.0dB automatically)
                    -9.0,  // 9.0 Buchla Folded
                    -10.4  // 10.0 Buchla Asym
                ]);
                
                final_osc * gain_db.dbamp;
            };

            mod1_chaos = Slew.kr(Latch.kr(WhiteNoise.kr.range(0, 1), Impulse.kr(mod1_chaos_rate * 4)), mod1_chaos_slew * 10, mod1_chaos_slew * 10);
            m1_shape_mod = (mod1_chaos * 2.0 - 1.0) * 0.25 * mod1_mix;
            m1_final_shape = (mod1_lfo_shape + m1_shape_mod).wrap(0, 1) * 3.0;
            mod1_lfo = SelectX.kr(m1_final_shape,[ LFPulse.kr(mod1_lfo_rate, 0, 0.5), (LFSaw.kr(mod1_lfo_rate, 0) + 1) * 0.5, (LFTri.kr(mod1_lfo_rate, 0) + 1) * 0.5, (SinOsc.kr(mod1_lfo_rate, 0) + 1) * 0.5 ]);
            mod1_sig = SelectX.kr(mod1_mix,[mod1_lfo, mod1_chaos]) * mod1_depth;

            mod2_chaos = Slew.kr(Latch.kr(WhiteNoise.kr.range(0, 1), Impulse.kr(mod2_chaos_rate * 4)), mod2_chaos_slew * 10, mod2_chaos_slew * 10);
            m2_shape_mod = (mod2_chaos * 2.0 - 1.0) * 0.25 * mod2_mix;
            m2_final_shape = (mod2_lfo_shape + m2_shape_mod).wrap(0, 1) * 3.0;
            mod2_lfo = SelectX.kr(m2_final_shape,[ LFPulse.kr(mod2_lfo_rate, 0, 0.5), (LFSaw.kr(mod2_lfo_rate, 0) + 1) * 0.5, (LFTri.kr(mod2_lfo_rate, 0) + 1) * 0.5, (SinOsc.kr(mod2_lfo_rate, 0) + 1) * 0.5 ]);
            mod2_sig = SelectX.kr(mod2_mix, [mod2_lfo, mod2_chaos]) * mod2_depth;

            mod3_chaos = Slew.kr(Latch.kr(WhiteNoise.kr.range(0, 1), Impulse.kr(mod3_chaos_rate * 4)), mod3_chaos_slew * 10, mod3_chaos_slew * 10);
            m3_shape_mod = (mod3_chaos * 2.0 - 1.0) * 0.25 * mod3_mix;
            m3_final_shape = (mod3_lfo_shape + m3_shape_mod).wrap(0, 1) * 3.0;
            mod3_lfo = SelectX.kr(m3_final_shape,[ LFPulse.kr(mod3_lfo_rate, 0, 0.5), (LFSaw.kr(mod3_lfo_rate, 0) + 1) * 0.5, (LFTri.kr(mod3_lfo_rate, 0) + 1) * 0.5, (SinOsc.kr(mod3_lfo_rate, 0) + 1) * 0.5 ]);
            mod3_sig = SelectX.kr(mod3_mix,[mod3_lfo, mod3_chaos]) * mod3_depth;

            env_int = LagUD.kr(gates.sum.clip(0,1), 0.01, 0.5);
            env_ext = Amplitude.kr(LeakDC.ar(SoundIn.ar(0))); 
            outline_sig = Select.kr(outline_source,[env_int, env_ext]) * outline_gain;

            calc_mod = { |dest_idx, arp_val|
                (mod1_sig * mod1_dest[dest_idx]) +
                (mod2_sig * mod2_dest[dest_idx]) +
                (mod3_sig * mod3_dest[dest_idx]) +
                (outline_sig * outline_dest[dest_idx]) +
                (arp_val * arp_dest[dest_idx]);
            };
            
            calc_mod_pitch = { |dest_idx, arp_val|
                var raw_mod1 = mod1_sig * mod1_dest[dest_idx] * 24.0;
                var raw_mod2 = mod2_sig * mod2_dest[dest_idx] * 24.0;
                var raw_mod3 = mod3_sig * mod3_dest[dest_idx] * 24.0;
                var raw_outline = outline_sig * outline_dest[dest_idx] * 24.0;
                var raw_arp = arp_val * arp_dest[dest_idx] * 24.0;
                
                var quantize_fn = { |raw|
                    var rounded = raw.round;
                    var oct = (rounded / 12).floor;
                    var pc = rounded % 12;
                    (oct * 12) + Select.kr(pc, scale_map);
                };
                
                var q_mod1 = Select.kr(mod1_quant[dest_idx],[raw_mod1, quantize_fn.(raw_mod1)]);
                var q_mod2 = Select.kr(mod2_quant[dest_idx],[raw_mod2, quantize_fn.(raw_mod2)]);
                var q_mod3 = Select.kr(mod3_quant[dest_idx],[raw_mod3, quantize_fn.(raw_mod3)]);
                var q_outline = Select.kr(outline_quant[dest_idx],[raw_outline, quantize_fn.(raw_outline)]);
                var q_arp = Select.kr(arp_quant[dest_idx],[raw_arp, quantize_fn.(raw_arp)]);
                
                (q_mod1 + q_mod2 + q_mod3 + q_outline + q_arp) / 12.0;
            };

            mw_norm = mod_wheel / 127.0; 
            bend_norm = (pitch_bend - 8192) / 8192.0;
            bend_offset = bend_norm * bend_range / 12.0;

            voices_out = 8.collect { |i|
                var p_idx = i % 4; 
                var d_sig = (LFNoise2.kr(0.01 + (i*0.001)) * drifts[p_idx] * (6/1200)) + (LFNoise2.kr(3.1 + (i*0.1)) * spreads[p_idx] * (3/1200));
                var s_freq = Lag.kr(freqs[i], glides[p_idx]);
                var s_vol = Lag.kr(vols[p_idx], 0.05);
                
                var m_pitch = calc_mod_pitch.(p_idx, arp_cvs[p_idx]);
                var m_amp = calc_mod.(p_idx + 4, arp_cvs[p_idx]);
                var m_shape = calc_mod.(p_idx + 8, arp_cvs[p_idx]);
                
                var mpe_bend_off = ((mpe_bends[i] - 8192) / 8192.0) * mpe_bend_range / 12.0;
                var midi_off = (midi_notes[i] - 60) / 12.0;
                
                var vel_bip = ((midi_vels[i] - 64) / 63.0).lincurve(-1.0, 1.0, -1.0, 1.0, vel_curve);
                var slide_n = Lag.kr(slides[i] / 127.0, mpe_lag).lincurve(0.0, 1.0, 0.0, 1.0, slide_curve);
                var press_n = Lag.kr(presses[i] / 127.0, mpe_lag).lincurve(0.0, 1.0, 0.0, 1.0, press_curve);
                
                var vca = (s_vol.squared + m_amp + (vel_bip * vel_amts[p_idx] * s_vol.squared) + (slide_n * slide_vols[p_idx]) + (press_n * press_vols[p_idx])).clip(0, 1);
                
                var final_shape = (shapes[p_idx] + (m_shape*10) + (vel_bip * vel_shps[p_idx] * 10) + (slide_n * slide_shps[p_idx] * 10) + (press_n * press_shps[p_idx] * 10) + (mw_norm * mw_shps[p_idx] * 10)).clip(0, 10);
                
                var final_atk = (env_atks[p_idx] + (vel_bip * vel_atks[p_idx] * 5.0)).clip(0.001, 10.0);
                
                var env = EnvGen.kr(Env.asr(final_atk, 1.0, env_rels[p_idx]), gates[i]);
                var osc = mk_osc.(s_freq * (2.pow(m_pitch + d_sig + bend_offset + mpe_bend_off + midi_off)), final_shape) * vca * env;
                
                var pan_val = pans[p_idx] * (i >= 4).if(-1.0, 1.0);
                Pan2.ar(osc, pan_val.clip(-1,1));
            };

            sig_mix = voices_out.sum * 0.125;

            s_filt1 = Lag.kr(filt1_cutoff, 0.05); 
            s_filt2 = Lag.kr(filt2_cutoff, 0.05);
            
            m_filt1 = calc_mod.(12, arp_cvs[0]) * 5000; 
            m_filt2 = calc_mod.(13, arp_cvs[0]) * 5000 + (mw_norm * mw_filt2 * 5000);

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

            m_delay_t = calc_mod.(14, arp_cvs[0]) * 0.1; 
            m_delay_f = calc_mod.(15, arp_cvs[0]) + (mw_norm * mw_delay_f);

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
        
        this.addCommand("set_matrix", "iif", { arg msg;
            var src = msg[1] - 1; 
            var dest = msg[2] - 1;
            var val = msg[3];
            var src_names =[\mod1_dest, \mod2_dest, \mod3_dest, \outline_dest, \arp_dest];
            matrix_amts[src][dest] = val;
            synth.set(src_names[src], matrix_amts[src]);
        });

        this.addCommand("set_matrix_quant", "iif", { arg msg;
            var src = msg[1] - 1;
            var dest = msg[2] - 1;
            var val = msg[3];
            var quant_names =[\mod1_quant, \mod2_quant, \mod3_quant, \outline_quant, \arp_quant];
            matrix_quants[src][dest] = val;
            synth.set(quant_names[src], matrix_quants[src]);
        });
        
        this.addCommand("query_config", "", { NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", 0); });
        NetAddr("127.0.0.1", 10111).sendMsg("/ltra/config", 0);
    }
    free { synth.free; osc_bridge.free; }
}
