import React, { useState } from 'react';
import { Settings, Play, ChevronLeft, Home, Check, Sparkles, SkipBack, SkipForward, Rewind, FastForward } from 'lucide-react';

export default function PlayerSettingsCoachmark() {
  const [dismissed, setDismissed] = useState(false);

  const c = {
    bg: '#f5f1e8',
    bgCard: '#fffdf7',
    gold: '#b8862f',
    goldLight: '#d4a047',
    goldSoft: '#fdf3df',
    goldFaint: '#fbe8c4',
    text: '#1a1612',
    textMuted: '#7a6f5e',
    border: '#e8e0d0',
    borderSoft: '#efe8d8',
    coral: '#e89b8a',
    serif: '"Cormorant Garamond", "Playfair Display", Georgia, serif',
    sans: '"SF Pro Text", -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif',
  };

  const StatusBar = () => (
    <div style={{ padding: '14px 28px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '15px', color: c.text, fontFamily: c.sans, fontWeight: 700, position: 'relative', zIndex: 10 }}>
      <span>4:04</span>
      <span style={{ fontSize: '11px', display: 'flex', gap: '4px', alignItems: 'center' }}>
        <span style={{ display: 'inline-block', width: '14px', height: '10px', background: c.text, borderRadius: '2px' }}></span>
        <span style={{ display: 'inline-block', width: '24px', height: '12px', border: `1.5px solid ${c.text}`, borderRadius: '3px', position: 'relative' }}>
          <span style={{ position: 'absolute', inset: '1.5px 4px 1.5px 1.5px', background: c.text, borderRadius: '1px' }}></span>
        </span>
      </span>
    </div>
  );

  return (
    <div style={{ minHeight: '100vh', background: '#2a241c', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px', fontFamily: c.serif, gap: '40px', flexWrap: 'wrap' }}>
      {/* Phone */}
      <div style={{ width: '380px', height: '780px', background: '#000', borderRadius: '48px', padding: '12px', boxShadow: '0 30px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.06)', position: 'relative', flexShrink: 0 }}>
        <div style={{ width: '100%', height: '100%', background: c.bg, borderRadius: '38px', overflow: 'hidden', position: 'relative' }}>
          {/* Notch */}
          <div style={{ position: 'absolute', top: '0', left: '50%', transform: 'translateX(-50%)', width: '120px', height: '28px', background: '#000', borderBottomLeftRadius: '16px', borderBottomRightRadius: '16px', zIndex: 50 }} />

          <StatusBar />

          {/* Player screen */}
          <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
            {/* Header: category + gear */}
            <div style={{ marginTop: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ fontSize: '11px', color: c.coral, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.18em' }}>
                CAREER · ALREADY DONE
              </div>
              {/* Gear icon - the target */}
              <div
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '50%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  position: 'relative',
                  zIndex: !dismissed ? 35 : 1,
                  background: !dismissed ? c.bgCard : 'transparent',
                  boxShadow: !dismissed ? `0 0 0 4px ${c.gold}40, 0 0 30px ${c.gold}80` : 'none',
                  animation: !dismissed ? 'pulse 2s infinite' : 'none',
                }}
              >
                <Settings size={20} color={c.text} strokeWidth={2} />
              </div>
            </div>

            {/* Story title */}
            <div style={{ marginTop: '10px', fontSize: '28px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.1 }}>
              The Success That Was<br />Always Yours<br />(Deepening #2)
            </div>
            <div style={{ marginTop: '8px', fontSize: '13px', color: c.textMuted, fontFamily: c.sans }}>
              02:38 · In your voice
            </div>

            {/* Waveform */}
            <div style={{ marginTop: '60px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '2px', height: '50px' }}>
              {[...Array(50)].map((_, i) => (
                <div
                  key={i}
                  style={{
                    width: '2px',
                    height: `${10 + Math.abs(Math.sin(i * 0.4)) * 30}px`,
                    background: c.border,
                    borderRadius: '1px',
                  }}
                />
              ))}
            </div>

            {/* Time + progress */}
            <div style={{ marginTop: '60px', display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: c.textMuted, fontFamily: c.sans }}>
              <span>00:01</span>
              <span>02:38</span>
            </div>
            <div style={{ marginTop: '6px', height: '3px', background: c.borderSoft, borderRadius: '2px', position: 'relative' }}>
              <div style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: '1%', background: c.gold, borderRadius: '2px' }} />
            </div>

            {/* Player controls */}
            <div style={{ marginTop: '18px', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px' }}>
              <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: c.borderSoft, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <SkipBack size={16} color={c.text} fill={c.text} />
              </div>
              <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: c.borderSoft, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Rewind size={16} color={c.text} fill={c.text} />
              </div>
              <div style={{ width: '54px', height: '54px', borderRadius: '50%', background: c.gold, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: `0 4px 14px ${c.gold}60` }}>
                <Play size={20} color="#fff" fill="#fff" style={{ marginLeft: '2px' }} />
              </div>
              <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: c.borderSoft, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <FastForward size={16} color={c.text} fill={c.text} />
              </div>
              <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: c.borderSoft, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <SkipForward size={16} color={c.text} fill={c.text} />
              </div>
            </div>

            {/* Deepen button */}
            <div style={{ marginTop: '18px', padding: '14px', background: c.goldSoft, border: `1.5px solid ${c.gold}`, borderRadius: '14px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
              <Sparkles size={14} color={c.gold} fill={c.gold} />
              <span style={{ fontSize: '14px', color: c.gold, fontFamily: c.sans, fontWeight: 700 }}>Deepen This Manifestation →</span>
            </div>

            {/* Bottom nav */}
            <div style={{ position: 'absolute', bottom: '0', left: '0', right: '0', padding: '12px 24px 28px', background: c.bgCard, borderTop: `1px solid ${c.borderSoft}`, display: 'flex', justifyContent: 'space-around' }}>
              {[
                { icon: '⌂', label: 'Home', active: false },
                { icon: '▶', label: 'Player', active: true },
                { icon: '✓', label: 'Done', active: false },
                { icon: '☰', label: 'Profile', active: false },
              ].map((item, i) => (
                <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px' }}>
                  <span style={{ fontSize: '18px', color: item.active ? c.gold : c.text, fontWeight: item.active ? 700 : 400 }}>{item.icon}</span>
                  <span style={{ fontSize: '11px', color: item.active ? c.gold : c.text, fontFamily: c.sans, fontWeight: item.active ? 700 : 500 }}>{item.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* DARKENING OVERLAY */}
          {!dismissed && (
            <div style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.55)', zIndex: 30, pointerEvents: 'none', animation: 'fadeIn 0.3s ease' }} />
          )}

          {/* COACHMARK */}
          {!dismissed && (
            <div
              style={{
                position: 'absolute',
                top: '110px',
                left: '20px',
                right: '20px',
                background: c.bgCard,
                borderRadius: '20px',
                padding: '20px',
                border: `1.5px solid ${c.gold}`,
                boxShadow: '0 20px 50px rgba(0,0,0,0.25), 0 0 60px rgba(184,134,47,0.2)',
                zIndex: 40,
                animation: 'slideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)',
              }}
            >
              {/* Arrow pointing up to the gear */}
              <div style={{
                position: 'absolute',
                top: '-10px',
                right: '20px',
                transform: 'rotate(45deg)',
                width: '18px',
                height: '18px',
                background: c.bgCard,
                borderLeft: `1.5px solid ${c.gold}`,
                borderTop: `1.5px solid ${c.gold}`,
              }} />

              <div style={{ fontSize: '10px', color: c.gold, letterSpacing: '0.18em', textTransform: 'uppercase', fontFamily: c.sans, fontWeight: 700, marginBottom: '8px' }}>
                Quick Tip
              </div>

              <div style={{ fontSize: '20px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.2, marginBottom: '8px' }}>
                Customize your experience
              </div>

              <div style={{ fontSize: '13px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.55, marginBottom: '16px' }}>
                Tap here to access <strong style={{ color: c.text }}>Sleep Mode</strong>, <strong style={{ color: c.text }}>Speed</strong>, and <strong style={{ color: c.text }}>Loop</strong>.
              </div>

              <button
                onClick={() => setDismissed(true)}
                style={{
                  width: '100%',
                  padding: '12px',
                  background: c.gold,
                  border: 'none',
                  borderRadius: '12px',
                  color: '#fff',
                  fontSize: '14px',
                  fontFamily: c.sans,
                  fontWeight: 600,
                  cursor: 'pointer',
                  boxShadow: `0 4px 12px ${c.gold}40`,
                }}
              >
                Got it
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Side panel */}
      <div style={{ maxWidth: '320px', color: c.bg }}>
        <div style={{ fontSize: '10px', letterSpacing: '0.25em', textTransform: 'uppercase', color: c.goldLight, fontFamily: c.sans, fontWeight: 700, marginBottom: '12px' }}>
          Player Coachmark
        </div>
        <div style={{ fontSize: '32px', fontFamily: c.serif, fontWeight: 500, color: c.bg, lineHeight: 1.05, marginBottom: '8px' }}>
          Settings <span style={{ fontStyle: 'italic', color: c.goldLight }}>Tip</span>
        </div>
        <div style={{ fontSize: '13px', color: '#a89b85', fontFamily: c.sans, lineHeight: 1.5, marginBottom: '24px' }}>
          One-time popup shown the first time a user reaches the Player screen, pointing to the gear icon.
        </div>

        <button
          onClick={() => setDismissed(!dismissed)}
          style={{
            width: '100%',
            padding: '12px',
            background: dismissed ? c.gold : 'rgba(255,255,255,0.05)',
            border: `1px solid ${dismissed ? c.gold : 'rgba(255,255,255,0.1)'}`,
            borderRadius: '10px',
            color: dismissed ? '#fff' : c.bg,
            fontSize: '13px',
            fontFamily: c.sans,
            fontWeight: 600,
            cursor: 'pointer',
            marginBottom: '20px',
          }}
        >
          {dismissed ? 'Show Coachmark' : 'Hide Coachmark'}
        </button>

        <div style={{ fontSize: '11px', color: '#a89b85', fontFamily: c.sans, lineHeight: 1.6 }}>
          <strong style={{ color: c.bg }}>Behavior notes:</strong><br />
          • Shows once per user (store in user prefs)<br />
          • Triggers on first Player screen visit<br />
          • Dismisses on "Got it" or tapping the gear<br />
          • Background dims to draw focus<br />
          • Arrow points up to highlighted gear
        </div>
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { box-shadow: 0 0 0 4px rgba(184,134,47,0.3), 0 0 30px rgba(184,134,47,0.5); }
          50% { box-shadow: 0 0 0 8px rgba(184,134,47,0.15), 0 0 50px rgba(184,134,47,0.7); }
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideIn { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }
      `}</style>
    </div>
  );
}
