import React, { useState } from 'react';
import { Plus, Play, Check } from 'lucide-react';

export default function NewManifestationCoachmark() {
  const [dismissed, setDismissed] = useState(false);

  const c = {
    bg: '#f5f1e8',
    bgCard: '#fffdf7',
    bgDark: '#1f1a14',
    gold: '#b8862f',
    goldLight: '#d4a047',
    goldSoft: '#fdf3df',
    goldFaint: '#fbe8c4',
    text: '#1a1612',
    textMuted: '#7a6f5e',
    border: '#e8e0d0',
    borderSoft: '#efe8d8',
    pink: '#fce4e4',
    peach: '#fde8d4',
    blueSoft: '#dde8f0',
    serif: '"Cormorant Garamond", "Playfair Display", Georgia, serif',
    sans: '"SF Pro Text", -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif',
  };

  const StatusBar = () => (
    <div style={{ padding: '14px 28px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '15px', color: c.text, fontFamily: c.sans, fontWeight: 700, position: 'relative', zIndex: 10 }}>
      <span>5:15</span>
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

          {/* Home screen */}
          <div style={{ position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
            {/* Dark header (compact, scrolled state) */}
            <div style={{ background: c.bgDark, padding: '14px 20px 18px' }}>
              <div style={{ fontSize: '10px', color: c.bg, fontFamily: c.sans, letterSpacing: '0.18em', fontWeight: 700, opacity: 0.85 }}>
                GOOD EVENING
              </div>
              <div style={{ fontSize: '24px', color: c.bg, fontFamily: c.serif, fontWeight: 500, marginTop: '2px', letterSpacing: '-0.01em' }}>
                Chris Josh
              </div>
              <div style={{ marginTop: '8px', display: 'inline-flex', alignItems: 'center', gap: '5px', padding: '4px 10px', background: 'rgba(255,255,255,0.08)', borderRadius: '20px', fontSize: '11px', color: c.gold, fontFamily: c.sans, fontWeight: 500 }}>
                <Check size={11} strokeWidth={2.5} />
                2-day streak
              </div>
            </div>

            {/* Scrollable content */}
            <div style={{ flex: 1, padding: '14px 20px 0', overflow: 'hidden' }}>
              {/* Your Manifestations heading */}
              <div style={{ fontSize: '15px', color: c.text, fontFamily: c.sans, fontWeight: 600, marginBottom: '10px' }}>
                Your Manifestations
              </div>

              {/* Filter pills */}
              <div style={{ display: 'flex', gap: '6px', marginBottom: '14px', overflow: 'hidden' }}>
                <div style={{ padding: '6px 14px', borderRadius: '20px', border: `1.5px solid ${c.gold}`, background: c.goldSoft, fontSize: '12px', color: c.gold, fontFamily: c.sans, fontWeight: 600, whiteSpace: 'nowrap' }}>
                  All Stories (18)
                </div>
                <div style={{ padding: '6px 14px', borderRadius: '20px', border: `1px solid ${c.border}`, background: c.bgCard, fontSize: '12px', color: c.textMuted, fontFamily: c.sans, fontWeight: 500, whiteSpace: 'nowrap' }}>
                  Love (0)
                </div>
                <div style={{ padding: '6px 14px', borderRadius: '20px', border: `1px solid ${c.border}`, background: c.bgCard, fontSize: '12px', color: c.textMuted, fontFamily: c.sans, fontWeight: 500, whiteSpace: 'nowrap' }}>
                  Money (7)
                </div>
              </div>

              {/* Recent Stories heading */}
              <div style={{ fontSize: '15px', color: c.text, fontFamily: c.sans, fontWeight: 600, marginBottom: '8px' }}>
                Recent Stories
              </div>

              {/* Story list */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {[
                  { title: 'The Success That Was Always Yours (Deepening #5)', time: '02:50', bg: c.pink },
                  { title: 'The Success That Was Always Yours (Deepening #4)', time: '02:53', bg: c.peach },
                  { title: 'The Success That Was Always Yours (Deepening #3)', time: '02:37', bg: c.blueSoft },
                ].map((item, i) => (
                  <div key={i} style={{ padding: '11px', background: c.bgCard, borderRadius: '12px', border: `1px solid ${c.borderSoft}`, display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ width: '38px', height: '38px', borderRadius: '8px', background: item.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Check size={16} color={c.text} strokeWidth={2.5} />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: '12px', color: c.text, fontFamily: c.sans, fontWeight: 600, lineHeight: 1.25 }}>{item.title}</div>
                      <div style={{ fontSize: '10px', color: c.textMuted, fontFamily: c.sans, marginTop: '2px' }}>· {item.time}</div>
                    </div>
                    <div style={{ width: '28px', height: '28px', borderRadius: '50%', border: `1px solid ${c.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Play size={10} color={c.text} fill={c.text} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Add Manifestation Button - positioned just above bottom nav */}
            <div style={{ padding: '14px 20px 14px' }}>
              <button
                style={{
                  width: '100%',
                  padding: '15px',
                  background: c.gold,
                  border: 'none',
                  borderRadius: '14px',
                  color: '#fff',
                  fontSize: '15px',
                  fontWeight: 600,
                  fontFamily: c.sans,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '10px',
                  cursor: 'pointer',
                  position: 'relative',
                  zIndex: !dismissed ? 35 : 1,
                  boxShadow: !dismissed ? `0 0 0 3px rgba(255,255,255,0.95), 0 0 30px rgba(255,255,255,0.7), 0 0 60px rgba(255,255,255,0.4)` : `0 4px 14px ${c.gold}40`,
                  animation: !dismissed ? 'pulseWhite 2s infinite' : 'none',
                }}
              >
                <Plus size={16} strokeWidth={2.5} />
                Add New Manifestation
              </button>
            </div>

            {/* Bottom nav with Home highlighted */}
            <div
              style={{
                padding: '10px 24px 24px',
                background: c.bgCard,
                borderTop: `1px solid ${c.borderSoft}`,
                display: 'flex',
                justifyContent: 'space-around',
                position: 'relative',
                zIndex: !dismissed ? 35 : 1,
              }}
            >
              {[
                { icon: '⌂', label: 'Home', active: true, target: true },
                { icon: '▶', label: 'Player', active: false },
                { icon: '✓', label: 'Done', active: false },
                { icon: '☰', label: 'Profile', active: false },
              ].map((item, i) => (
                <div
                  key={i}
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '3px',
                    padding: !dismissed && item.target ? '5px 12px' : '0',
                    borderRadius: '12px',
                    background: !dismissed && item.target ? c.goldSoft : 'transparent',
                    boxShadow: !dismissed && item.target ? `0 0 0 3px ${c.gold}80, 0 0 25px ${c.gold}80` : 'none',
                    animation: !dismissed && item.target ? 'pulse 2s infinite' : 'none',
                  }}
                >
                  <span style={{ fontSize: '17px', color: item.active ? c.gold : c.text, fontWeight: item.active ? 700 : 400 }}>{item.icon}</span>
                  <span style={{ fontSize: '10px', color: item.active ? c.gold : c.text, fontFamily: c.sans, fontWeight: item.active ? 700 : 500 }}>{item.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* DARKENING OVERLAY */}
          {!dismissed && (
            <div style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.55)', zIndex: 30, pointerEvents: 'none', animation: 'fadeIn 0.3s ease' }} />
          )}

          {/* COACHMARK - centered on screen */}
          {!dismissed && (
            <div
              style={{
                position: 'absolute',
                top: '50%',
                transform: 'translateY(-50%)',
                left: '20px',
                right: '20px',
                background: c.bgCard,
                borderRadius: '20px',
                padding: '22px 20px',
                border: `1.5px solid ${c.gold}`,
                boxShadow: '0 20px 50px rgba(0,0,0,0.25), 0 0 60px rgba(184,134,47,0.2)',
                zIndex: 40,
                animation: 'slideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)',
              }}
            >
              <div style={{ fontSize: '10px', color: c.gold, letterSpacing: '0.18em', textTransform: 'uppercase', fontFamily: c.sans, fontWeight: 700, marginBottom: '8px' }}>
                Quick Tip
              </div>

              <div style={{ fontSize: '22px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.2, marginBottom: '10px' }}>
                Create new manifestations
              </div>

              <div style={{ fontSize: '13px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.55, marginBottom: '18px' }}>
                Tap <strong style={{ color: c.text }}>Home</strong> in the navigation, then scroll down and tap <strong style={{ color: c.text }}>+ Add New Manifestation</strong> to create a new story.
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
          New Manifestation Coachmark
        </div>
        <div style={{ fontSize: '32px', fontFamily: c.serif, fontWeight: 500, color: c.bg, lineHeight: 1.05, marginBottom: '8px' }}>
          Create New <span style={{ fontStyle: 'italic', color: c.goldLight }}>Tip</span>
        </div>
        <div style={{ fontSize: '13px', color: '#a89b85', fontFamily: c.sans, lineHeight: 1.5, marginBottom: '24px' }}>
          One-time popup highlighting both the Home tab AND the + Add New Manifestation button on the home screen.
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
          • Triggers when user lands on Home screen post-onboarding<br />
          • Two elements highlighted: Home tab + Add button<br />
          • Dismisses on "Got it" or tapping either element<br />
          • Background dims to draw focus to both highlights
        </div>
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { box-shadow: 0 0 0 3px rgba(184,134,47,0.5), 0 0 25px rgba(184,134,47,0.5); }
          50% { box-shadow: 0 0 0 6px rgba(184,134,47,0.25), 0 0 40px rgba(184,134,47,0.7); }
        }
        @keyframes pulseWhite {
          0%, 100% { box-shadow: 0 0 0 3px rgba(255,255,255,0.95), 0 0 30px rgba(255,255,255,0.7), 0 0 60px rgba(255,255,255,0.4); }
          50% { box-shadow: 0 0 0 6px rgba(255,255,255,0.6), 0 0 45px rgba(255,255,255,0.9), 0 0 80px rgba(255,255,255,0.5); }
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideIn { from { opacity: 0; transform: translate(0, calc(-50% + 10px)); } to { opacity: 1; transform: translate(0, -50%); } }
      `}</style>
    </div>
  );
}
