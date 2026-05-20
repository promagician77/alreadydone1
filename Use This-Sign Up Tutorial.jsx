import React, { useState } from 'react';
import { Plus, Play, Heart, DollarSign, Sparkles, Home, ChevronLeft, ChevronRight, ArrowDown, ArrowUp, Check, Lock, Mic, Headphones, RefreshCw, Star } from 'lucide-react';

export default function AlreadyDoneTutorial() {
  const [step, setStep] = useState(0);
  const [flow, setFlow] = useState('pre');

  const preFlowSteps = [
    {
      screen: 'personalize',
      title: 'Quick Tutorial First',
      body: "Just follow along, no need to fill anything in yet. On this screen, you'll enter your name, dream location, energy word, and someone you love. These details make every story unique to you. You'll set everything up when the tutorial ends.",
      target: 'personalize-form',
      cardPosition: 'bottom',
      arrowDirection: 'up',
    },
    {
      screen: 'category',
      title: 'Choose a Category',
      body: 'Pick the area of life you want to manifest. Love, Money, Career/Business, Health, or Home.',
      target: 'categories',
      cardPosition: 'bottom',
      arrowDirection: 'up',
    },
    {
      screen: 'category',
      title: 'Describe What\'s Already Yours',
      body: 'Write your desired manifestation. Write it like it already happened. Be specific. Be emotional.',
      target: 'desire-input',
      cardPosition: 'bottom',
      arrowDirection: 'up',
    },
    {
      screen: 'category',
      title: 'Tap "Create My Story"',
      body: 'Once you\'ve described your manifestation, tap the gold button to continue building your story.',
      target: 'create-button',
      cardPosition: 'top',
      arrowDirection: 'down',
    },
    {
      screen: 'paywall',
      title: 'Unlock Your Voice',
      body: "Start your 3-day free trial. Tap the gold button to unlock unlimited stories in your own voice.",
      target: 'paywall-cta',
      cardPosition: 'top',
      arrowDirection: 'down',
      isPaywall: true,
    },
  ];

  const postFlowSteps = [
    {
      screen: 'voice-select',
      title: "Voice Selection",
      body: "Now choose the voice that will narrate your manifestations. Your own voice is most powerful.",
      target: null,
      cardPosition: 'center',
    },
    {
      screen: 'voice-select',
      title: 'Pick "My Voice"',
      body: 'Select My Voice to clone yours, or pick from our pre-made voices to start instantly.',
      target: 'voice-options',
      cardPosition: 'bottom',
      arrowDirection: 'up',
    },
    {
      screen: 'voice-record',
      title: 'Tap "Start Recording"',
      body: 'Read the passage aloud 3 times, slowly and clearly. Recording auto-completes at 30 seconds.',
      target: 'start-recording',
      cardPosition: 'top',
      arrowDirection: 'down',
    },
    {
      screen: 'voice-clone',
      title: 'Tap "Create Clone Voice"',
      body: 'Your recording is ready. Tap the gold button to create your custom voice. Takes 30 to 45 seconds.',
      target: 'clone-button',
      cardPosition: 'top',
      arrowDirection: 'down',
    },
    {
      screen: 'voice-clone',
      title: "It's Already Done",
      body: 'Your voice is ready. Every manifestation will now be narrated in your own voice. Welcome home.',
      target: null,
      cardPosition: 'center',
      isFinal: true,
    },
  ];

  const tutorialSteps = flow === 'pre' ? preFlowSteps : postFlowSteps;
  const current = tutorialSteps[step];

  const handleNext = () => {
    if (step < tutorialSteps.length - 1) setStep(step + 1);
    else {
      if (flow === 'pre') { setFlow('post'); setStep(0); }
      else { setFlow('pre'); setStep(0); }
    }
  };

  const handleSkip = () => setStep(tutorialSteps.length - 1);

  const switchFlow = (newFlow) => { setFlow(newFlow); setStep(0); };

  // Color tokens from the actual app
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
    greenSoft: '#e3f0e0',
    green: '#5a8a4a',
    serif: '"Cormorant Garamond", "Playfair Display", Georgia, serif',
    sans: '"SF Pro Text", -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif',
  };

  // Status bar
  const StatusBar = () => (
    <div style={{ padding: '14px 28px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '15px', color: c.text, fontFamily: c.sans, fontWeight: 700, position: 'relative', zIndex: 10 }}>
      <span>10:08</span>
      <span style={{ fontSize: '11px', display: 'flex', gap: '4px', alignItems: 'center' }}>
        <span style={{ display: 'inline-block', width: '14px', height: '10px', background: c.text, borderRadius: '2px' }}></span>
        <span style={{ display: 'inline-block', width: '24px', height: '12px', border: `1.5px solid ${c.text}`, borderRadius: '3px', position: 'relative' }}>
          <span style={{ position: 'absolute', inset: '1.5px 4px 1.5px 1.5px', background: c.text, borderRadius: '1px' }}></span>
        </span>
      </span>
    </div>
  );

  // Bottom nav
  const BottomNav = ({ active = 'Home' }) => (
    <div style={{ position: 'absolute', bottom: '0', left: '0', right: '0', padding: '12px 24px 28px', background: c.bgCard, borderTop: `1px solid ${c.borderSoft}`, display: 'flex', justifyContent: 'space-around' }}>
      {[
        { icon: '⌂', label: 'Home' },
        { icon: '▶', label: 'Player' },
        { icon: '✓', label: 'Done' },
        { icon: '☰', label: 'Profile' },
      ].map((item, i) => (
        <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px' }}>
          <span style={{ fontSize: '18px', color: active === item.label ? c.gold : c.text, fontWeight: active === item.label ? 700 : 400 }}>{item.icon}</span>
          <span style={{ fontSize: '11px', color: active === item.label ? c.gold : c.text, fontFamily: c.sans, fontWeight: active === item.label ? 700 : 500 }}>{item.label}</span>
        </div>
      ))}
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

          {/* PERSONALIZATION SCREEN */}
          {current.screen === 'personalize' && (
            <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              {/* Back chevron */}
              <div style={{ marginTop: '12px' }}>
                <ChevronLeft size={22} color={c.gold} strokeWidth={2} />
              </div>

              {/* Progress bar - step 1 of 4 */}
              <div style={{ marginTop: '14px', display: 'flex', gap: '6px' }}>
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
              </div>

              {/* Headline */}
              <div style={{ marginTop: '14px', fontSize: '22px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.2 }}>
                First, let's personalize<br />your experience
              </div>
              <div style={{ marginTop: '6px', fontSize: '12px', color: c.textMuted, fontFamily: c.sans }}>
                These details make every story unique to you
              </div>

              {/* Form (highlighted as one block) */}
              <div
                style={{
                  marginTop: '14px',
                  position: 'relative',
                  zIndex: current.target === 'personalize-form' ? 35 : 1,
                  padding: current.target === 'personalize-form' ? '10px' : '0',
                  margin: current.target === 'personalize-form' ? '14px -10px 0' : '14px 0 0',
                  borderRadius: '16px',
                  boxShadow: current.target === 'personalize-form' ? `0 0 0 3px ${c.gold}80, 0 0 30px ${c.gold}60` : 'none',
                  background: current.target === 'personalize-form' ? `${c.gold}15` : 'transparent',
                  animation: current.target === 'personalize-form' ? 'pulse 2s infinite' : 'none',
                }}
              >
                {/* First Name */}
                <div style={{ fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>
                  Your First Name
                </div>
                <div style={{ marginTop: '6px', padding: '12px 14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '10px', fontSize: '13px', color: c.textMuted, fontFamily: c.sans }}>
                  Jordan
                </div>

                {/* Location */}
                <div style={{ marginTop: '14px', fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>
                  Where does your dream life take place?
                </div>
                <div style={{ marginTop: '2px', fontSize: '11px', color: c.textMuted, fontFamily: c.sans }}>
                  City or country
                </div>
                <div style={{ marginTop: '6px', padding: '12px 14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '10px', fontSize: '13px', color: c.textMuted, fontFamily: c.sans }}>
                  Bali
                </div>

                {/* Popular locations - condensed preview */}
                <div style={{ marginTop: '10px', fontSize: '10px', color: c.text, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.15em' }}>
                  POPULAR LOCATIONS
                </div>
                <div style={{ marginTop: '6px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '5px' }}>
                  {['New York City', 'Paris', 'Bali', 'Tokyo', 'Miami', 'London'].map((loc, i) => (
                    <div key={i} style={{ padding: '6px 4px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '20px', fontSize: '10px', color: c.text, fontFamily: c.sans, fontWeight: 500, textAlign: 'center' }}>
                      {loc}
                    </div>
                  ))}
                </div>

                {/* Energy Word */}
                <div style={{ marginTop: '14px', fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>
                  Choose Your Energy Word
                </div>
                <div style={{ marginTop: '6px', display: 'flex', gap: '5px', flexWrap: 'wrap' }}>
                  {[
                    { label: 'Powerful', selected: true },
                    { label: 'Peaceful', selected: false },
                    { label: 'Abundant', selected: false },
                  ].map((w, i) => (
                    <div key={i} style={{ padding: '5px 12px', background: w.selected ? c.goldSoft : c.bgCard, border: `1px solid ${w.selected ? c.gold : c.borderSoft}`, borderRadius: '20px', fontSize: '11px', color: w.selected ? c.gold : c.textMuted, fontFamily: c.sans, fontWeight: 600 }}>
                      {w.label}
                    </div>
                  ))}
                </div>
              </div>

              {/* Continue button */}
              <button style={{ width: '100%', marginTop: '14px', padding: '14px', background: c.gold, border: 'none', borderRadius: '14px', color: '#fff', fontSize: '14px', fontWeight: 600, fontFamily: c.sans, cursor: 'pointer', boxShadow: `0 4px 14px ${c.gold}40` }}>
                Continue
              </button>
            </div>
          )}

          {/* HOME SCREEN */}
          {current.screen === 'home' && (
            <div style={{ position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              {/* Dark header block */}
              <div style={{ background: c.bgDark, padding: '20px 24px 28px', margin: '0' }}>
                <div style={{ fontSize: '11px', color: c.bg, fontFamily: c.sans, letterSpacing: '0.18em', fontWeight: 700, opacity: 0.85 }}>
                  GOOD MORNING
                </div>
                <div style={{ fontSize: '32px', color: c.bg, fontFamily: c.serif, fontWeight: 500, marginTop: '4px', letterSpacing: '-0.01em' }}>
                  Chris Josh
                </div>
                <div style={{ marginTop: '10px', display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '6px 12px', background: 'rgba(255,255,255,0.08)', borderRadius: '20px', fontSize: '12px', color: c.gold, fontFamily: c.sans, fontWeight: 500 }}>
                  <Check size={12} strokeWidth={2.5} />
                  3-day streak
                </div>
              </div>

              {/* Scrollable content - showing bottom of home */}
              <div style={{ padding: '20px 20px 100px', height: 'calc(100% - 130px)', overflow: 'hidden' }}>
                {/* Filter pills */}
                <div style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
                  <div style={{ padding: '8px 16px', borderRadius: '20px', border: `1.5px solid ${c.gold}`, background: c.goldSoft, fontSize: '13px', color: c.gold, fontFamily: c.sans, fontWeight: 600 }}>
                    All Stories (9)
                  </div>
                  <div style={{ padding: '8px 16px', borderRadius: '20px', border: `1px solid ${c.border}`, background: c.bgCard, fontSize: '13px', color: c.textMuted, fontFamily: c.sans, fontWeight: 500 }}>
                    Love (0)
                  </div>
                  <div style={{ padding: '8px 16px', borderRadius: '20px', border: `1px solid ${c.border}`, background: c.bgCard, fontSize: '13px', color: c.textMuted, fontFamily: c.sans, fontWeight: 500 }}>
                    Money (6)
                  </div>
                </div>

                {/* Recent Stories */}
                <div style={{ fontSize: '17px', color: c.text, fontFamily: c.serif, fontWeight: 600, marginBottom: '12px' }}>
                  Recent Stories
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {[
                    { title: 'The Mansion That Was Always Mine (Deepening #1)', time: '03:25', bg: c.pink },
                    { title: 'The Mansion That Was Always Mine', time: '03:10', bg: c.peach },
                    { title: 'The Energy That Was Always Mine', time: '02:59', bg: c.blueSoft },
                  ].map((item, i) => (
                    <div key={i} style={{ padding: '14px', background: c.bgCard, borderRadius: '14px', border: `1px solid ${c.borderSoft}`, display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div style={{ width: '44px', height: '44px', borderRadius: '8px', background: item.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Check size={18} color={c.text} strokeWidth={2.5} />
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 600, lineHeight: 1.3 }}>{item.title}</div>
                        <div style={{ fontSize: '11px', color: c.textMuted, fontFamily: c.sans, marginTop: '2px' }}>· {item.time}</div>
                      </div>
                      <div style={{ width: '32px', height: '32px', borderRadius: '50%', border: `1px solid ${c.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                        <Play size={12} color={c.text} fill={c.text} />
                      </div>
                    </div>
                  ))}
                </div>

                {/* Add Manifestation Button - the target */}
                <button
                  style={{
                    width: '100%',
                    marginTop: '20px',
                    padding: '17px',
                    background: c.gold,
                    border: 'none',
                    borderRadius: '14px',
                    color: '#fff',
                    fontSize: '16px',
                    fontWeight: 600,
                    fontFamily: c.sans,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '10px',
                    cursor: 'pointer',
                    boxShadow: current.target === 'add-button' ? `0 0 0 4px ${c.gold}40, 0 0 40px ${c.gold}80` : `0 4px 14px ${c.gold}40`,
                    position: 'relative',
                    zIndex: current.target === 'add-button' ? 35 : 1,
                    animation: current.target === 'add-button' ? 'pulse 2s infinite' : 'none',
                  }}
                >
                  <Plus size={18} strokeWidth={2.5} />
                  Add New Manifestation
                </button>
              </div>

              <BottomNav active="Home" />
            </div>
          )}

          {/* CATEGORY SCREEN */}
          {current.screen === 'category' && (
            <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              {/* Back chevron */}
              <div style={{ marginTop: '12px' }}>
                <ChevronLeft size={22} color={c.gold} strokeWidth={2} />
              </div>

              {/* Progress bar */}
              <div style={{ marginTop: '14px', display: 'flex', gap: '6px' }}>
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
              </div>

              {/* Show heading only when target is categories or null on this screen */}
              {(current.target === 'categories' || !current.target) && (
                <>
                  <div style={{ marginTop: '16px', fontSize: '22px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.2 }}>
                    What's already done<br />for you?
                  </div>
                  <div style={{ marginTop: '4px', fontSize: '13px', color: c.textMuted, fontFamily: c.sans }}>
                    Choose a category
                  </div>
                </>
              )}

              {/* Categories grid - shown when target is categories */}
              {(current.target === 'categories' || !current.target) && (
                <div
                  style={{
                    marginTop: '14px',
                    position: 'relative',
                    zIndex: current.target === 'categories' ? 35 : 1,
                    padding: current.target === 'categories' ? '8px' : '0',
                    margin: current.target === 'categories' ? '14px -8px 0' : '14px 0 0',
                    borderRadius: '18px',
                    boxShadow: current.target === 'categories' ? `0 0 0 3px ${c.gold}60` : 'none',
                    background: current.target === 'categories' ? `${c.gold}10` : 'transparent',
                  }}
                >
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                    {[
                      { Icon: Heart, label: 'Love', selected: true },
                      { Icon: DollarSign, label: 'Money', selected: false },
                      { Icon: Sparkles, label: 'Career/Business', selected: false },
                      { emoji: '🌿', label: 'Health', selected: false },
                      { emoji: '🏠', label: 'Home', selected: false },
                    ].map((item, i) => (
                      <div
                        key={i}
                        style={{
                          padding: '14px',
                          background: item.selected ? c.goldFaint : c.bgCard,
                          border: `1.5px solid ${item.selected ? c.gold : c.borderSoft}`,
                          borderRadius: '12px',
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '6px',
                          minHeight: '70px',
                        }}
                      >
                        {item.Icon ? (
                          <item.Icon size={18} color={c.text} strokeWidth={2} fill="transparent" />
                        ) : (
                          <span style={{ fontSize: '18px' }}>{item.emoji}</span>
                        )}
                        <div style={{ fontSize: '12px', color: c.text, fontFamily: c.sans, fontWeight: 600 }}>
                          {item.label}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* When desire-input or create-button is targeted, show only desire field and create button */}
              {(current.target === 'desire-input' || current.target === 'create-button') && (
                <>
                  {/* Subtle context: scrolled past categories indicator */}
                  <div style={{ marginTop: '14px', textAlign: 'center', fontSize: '11px', color: c.textMuted, fontFamily: c.sans, fontStyle: 'italic', opacity: 0.7 }}>
                    ↑ Categories above
                  </div>

                  {/* Description / Desire input - positioned high on screen */}
                  <div
                    style={{
                      marginTop: '14px',
                      position: 'relative',
                      zIndex: current.target === 'desire-input' ? 35 : 1,
                      padding: current.target === 'desire-input' ? '10px' : '0',
                      margin: current.target === 'desire-input' ? '14px -10px 0' : '14px 0 0',
                      borderRadius: '16px',
                      boxShadow: current.target === 'desire-input' ? `0 0 0 3px ${c.gold}80, 0 0 30px ${c.gold}60` : 'none',
                      background: current.target === 'desire-input' ? `${c.gold}15` : 'transparent',
                      animation: current.target === 'desire-input' ? 'pulse 2s infinite' : 'none',
                    }}
                  >
                    <div style={{ fontSize: '14px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>
                      Describe What's Already Yours
                    </div>
                    <div style={{ marginTop: '2px', fontSize: '11px', color: c.textMuted, fontFamily: c.sans }}>
                      (Write Your Desired Manifestation Here)
                    </div>
                    <div style={{ marginTop: '10px', padding: '14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '12px', minHeight: '110px' }}>
                      <div style={{ fontSize: '12px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.5 }}>
                        Write it like it already happened. Be specific. Be emotional.
                      </div>
                      <div style={{ marginTop: '10px', fontSize: '12px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.5 }}>
                        Example: The deeply loving relationship where I felt completely seen, valued, and cherished every single...
                      </div>
                    </div>
                  </div>

                  {/* Create button - shown on both desire-input and create-button steps */}
                  <button
                    style={{
                      width: '100%',
                      marginTop: '20px',
                      padding: '16px',
                      background: c.gold,
                      border: 'none',
                      borderRadius: '14px',
                      color: '#fff',
                      fontSize: '15px',
                      fontWeight: 600,
                      fontFamily: c.sans,
                      cursor: 'pointer',
                      boxShadow: current.target === 'create-button' ? `0 0 0 4px ${c.gold}40, 0 0 40px ${c.gold}80` : `0 4px 14px ${c.gold}40`,
                      position: 'relative',
                      zIndex: current.target === 'create-button' ? 35 : 1,
                      animation: current.target === 'create-button' ? 'pulse 2s infinite' : 'none',
                    }}
                  >
                    Create My Story
                  </button>
                </>
              )}

              {/* Create button - shown when categories targeted (at bottom, dimmed by overlay) */}
              {current.target === 'categories' && (
                <button
                  style={{
                    width: '100%',
                    marginTop: '14px',
                    padding: '14px',
                    background: c.gold,
                    border: 'none',
                    borderRadius: '14px',
                    color: '#fff',
                    fontSize: '14px',
                    fontWeight: 600,
                    fontFamily: c.sans,
                    cursor: 'pointer',
                    boxShadow: `0 4px 14px ${c.gold}40`,
                  }}
                >
                  Create My Story
                </button>
              )}
            </div>
          )}

          {/* PAYWALL */}
          {current.screen === 'paywall' && (
            <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              <div style={{ marginTop: '12px' }}>
                <ChevronLeft size={22} color={c.text} strokeWidth={1.5} />
              </div>

              <div style={{ marginTop: '20px', textAlign: 'center', fontSize: '28px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.1 }}>
                Your dream life.<br />
                <span style={{ fontStyle: 'italic', color: c.gold, fontWeight: 400 }}>Already done.</span>
              </div>
              <div style={{ marginTop: '8px', textAlign: 'center', fontSize: '13px', color: c.textMuted, fontFamily: c.sans }}>
                Unlimited stories in your voice
              </div>

              {/* Trust card */}
              <div style={{ marginTop: '18px', padding: '14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '14px' }}>
                <div style={{ textAlign: 'center', fontSize: '10px', color: c.text, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.18em', marginBottom: '10px' }}>
                  TRUSTED BY THOUSANDS
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-around' }}>
                  {[
                    { value: '4.8★', label: 'RATING' },
                    { value: '50K+', label: 'STORIES' },
                    { value: '12K+', label: 'USERS' },
                  ].map((stat, i) => (
                    <div key={i} style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: '17px', color: c.gold, fontFamily: c.serif, fontWeight: 600 }}>{stat.value}</div>
                      <div style={{ fontSize: '9px', color: c.textMuted, fontFamily: c.sans, fontWeight: 600, letterSpacing: '0.12em', marginTop: '2px' }}>{stat.label}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* CTA */}
              <button
                style={{
                  width: '100%',
                  marginTop: '14px',
                  padding: '14px',
                  background: `linear-gradient(135deg, ${c.goldLight} 0%, ${c.gold} 100%)`,
                  border: 'none',
                  borderRadius: '30px',
                  color: '#fff',
                  fontSize: '14px',
                  fontWeight: 700,
                  fontFamily: c.sans,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '8px',
                  cursor: 'pointer',
                  boxShadow: current.target === 'paywall-cta' ? `0 0 0 4px ${c.gold}40, 0 0 40px ${c.gold}80` : `0 4px 14px ${c.gold}40`,
                  position: 'relative',
                  zIndex: current.target === 'paywall-cta' ? 35 : 1,
                  animation: current.target === 'paywall-cta' ? 'pulse 2s infinite' : 'none',
                }}
              >
                <Sparkles size={14} fill="#fff" />
                Start your 3-day free trial today
              </button>

              {/* Monthly plan */}
              <div style={{ marginTop: '14px', padding: '14px', background: c.greenSoft, border: `2px solid ${c.green}`, borderRadius: '14px', position: 'relative' }}>
                <div style={{ position: 'absolute', top: '-9px', right: '12px', padding: '3px 10px', background: c.green, borderRadius: '20px', fontSize: '9px', color: '#fff', fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.1em' }}>
                  CURRENT PLAN
                </div>
                <div style={{ fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>Monthly</div>
                <div style={{ marginTop: '2px', fontSize: '24px', color: c.text, fontFamily: c.sans, fontWeight: 800 }}>
                  $14.99 <span style={{ fontSize: '12px', color: c.textMuted, fontWeight: 500 }}>/month</span>
                </div>
                <div style={{ marginTop: '6px', display: 'inline-block', padding: '3px 8px', background: '#d4ead0', borderRadius: '6px', fontSize: '10px', color: c.green, fontFamily: c.sans, fontWeight: 600 }}>
                  Save 30% vs weekly plan
                </div>
                <div style={{ marginTop: '8px', fontSize: '11px', color: c.text, fontFamily: c.sans }}>
                  Billed monthly · Cancel anytime
                </div>
              </div>

              {/* Weekly plan preview */}
              <div style={{ marginTop: '10px', padding: '14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '14px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>Weekly</div>
                    <div style={{ marginTop: '2px', fontSize: '20px', color: c.text, fontFamily: c.sans, fontWeight: 800 }}>
                      $4.99 <span style={{ fontSize: '11px', color: c.textMuted, fontWeight: 500 }}>/week</span>
                    </div>
                  </div>
                  <div style={{ width: '20px', height: '20px', borderRadius: '50%', border: `1.5px solid ${c.border}` }} />
                </div>
              </div>
            </div>
          )}

          {/* VOICE SELECT */}
          {current.screen === 'voice-select' && (
            <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              <div style={{ marginTop: '12px' }}>
                <ChevronLeft size={22} color={c.gold} strokeWidth={2} />
              </div>

              <div style={{ marginTop: '14px', display: 'flex', gap: '6px' }}>
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
              </div>

              {/* My Voice card */}
              <div
                style={{
                  marginTop: '18px',
                  position: 'relative',
                  zIndex: current.target === 'voice-options' ? 35 : 1,
                }}
              >
                <div style={{
                  padding: '16px',
                  background: c.goldFaint,
                  border: `2px solid ${c.gold}`,
                  borderRadius: '14px',
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '12px',
                  boxShadow: current.target === 'voice-options' ? `0 0 0 3px ${c.gold}40` : 'none',
                }}>
                  <div style={{ width: '20px', height: '20px', borderRadius: '50%', border: `2px solid ${c.gold}`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: '2px' }}>
                    <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: c.gold }} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                      <span style={{ fontSize: '17px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>My Voice</span>
                      <span style={{ padding: '3px 8px', background: c.gold, borderRadius: '4px', fontSize: '9px', color: '#fff', fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.08em' }}>RECOMMENDED</span>
                    </div>
                    <div style={{ marginTop: '4px', fontSize: '12px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.4 }}>
                      Your own cloned voice — the most powerful for manifestation
                    </div>
                  </div>
                </div>
              </div>

              <div style={{ marginTop: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ flex: 1, height: '1px', background: c.border }} />
                <span style={{ fontSize: '10px', color: c.textMuted, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.18em' }}>OR CHOOSE A PRE-MADE VOICE</span>
                <div style={{ flex: 1, height: '1px', background: c.border }} />
              </div>

              <div style={{ marginTop: '16px', fontSize: '11px', color: c.text, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.15em' }}>MALE VOICES</div>

              <div style={{ marginTop: '8px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {[
                  { name: 'Matt', desc: 'Warm & Soothing' },
                  { name: 'David', desc: 'Confident & Powerful' },
                ].map((v, i) => (
                  <div key={i} style={{ padding: '12px 14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '18px', height: '18px', borderRadius: '50%', border: `1.5px solid ${c.border}`, flexShrink: 0 }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '14px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>{v.name}</div>
                      <div style={{ fontSize: '11px', color: c.textMuted, fontFamily: c.sans, marginTop: '1px' }}>{v.desc}</div>
                    </div>
                    <div style={{ width: '28px', height: '28px', borderRadius: '50%', border: `1px solid ${c.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Play size={10} color={c.text} fill={c.text} />
                    </div>
                  </div>
                ))}
              </div>

              <div style={{ marginTop: '14px', fontSize: '11px', color: c.text, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.15em' }}>FEMALE VOICES</div>

              <div style={{ marginTop: '8px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {[
                  { name: 'Sarah', desc: 'Warm & Nurturing' },
                ].map((v, i) => (
                  <div key={i} style={{ padding: '12px 14px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '18px', height: '18px', borderRadius: '50%', border: `1.5px solid ${c.border}`, flexShrink: 0 }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '14px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>{v.name}</div>
                      <div style={{ fontSize: '11px', color: c.textMuted, fontFamily: c.sans, marginTop: '1px' }}>{v.desc}</div>
                    </div>
                    <div style={{ width: '28px', height: '28px', borderRadius: '50%', border: `1px solid ${c.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Play size={10} color={c.text} fill={c.text} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* VOICE RECORD */}
          {current.screen === 'voice-record' && (
            <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              <div style={{ marginTop: '12px' }}>
                <ChevronLeft size={22} color={c.gold} strokeWidth={2} />
              </div>

              <div style={{ marginTop: '14px', display: 'flex', gap: '6px' }}>
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
              </div>

              <div style={{ marginTop: '18px', textAlign: 'center', fontSize: '24px', color: c.text, fontFamily: c.serif, fontWeight: 500 }}>
                Clone Your Voice
              </div>
              <div style={{ marginTop: '4px', textAlign: 'center', fontSize: '12px', color: c.textMuted, fontFamily: c.sans }}>
                Record yourself reading the words below
              </div>

              {/* Mic circle */}
              <div style={{ marginTop: '18px', display: 'flex', justifyContent: 'center' }}>
                <div style={{ width: '80px', height: '80px', borderRadius: '50%', border: `1.5px solid ${c.border}`, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', background: c.bgCard }}>
                  <span style={{ fontSize: '22px' }}>🎙️</span>
                  <div style={{ fontSize: '14px', color: c.text, fontFamily: c.sans, fontWeight: 700, marginTop: '-2px' }}>0:30</div>
                </div>
              </div>

              {/* Script */}
              <div style={{ marginTop: '16px', padding: '14px', background: c.bgCard, border: `1.5px solid ${c.gold}`, borderRadius: '14px' }}>
                <div style={{ textAlign: 'center', fontSize: '10px', color: c.gold, fontFamily: c.sans, fontWeight: 700, letterSpacing: '0.18em' }}>
                  READ THIS ALOUD 3 TIMES
                </div>
                <div style={{ marginTop: '10px', fontSize: '12px', color: c.text, fontFamily: c.serif, lineHeight: 1.5, textAlign: 'center' }}>
                  Three months later, I stood on the private terrace of my Newport Coast estate, watching the sunrise paint the Pacific in liquid gold...
                </div>
              </div>

              {/* Start Recording button */}
              <button
                style={{
                  width: '100%',
                  marginTop: '16px',
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
                  boxShadow: current.target === 'start-recording' ? `0 0 0 4px ${c.gold}40, 0 0 40px ${c.gold}80` : `0 4px 14px ${c.gold}40`,
                  position: 'relative',
                  zIndex: current.target === 'start-recording' ? 35 : 1,
                  animation: current.target === 'start-recording' ? 'pulse 2s infinite' : 'none',
                }}
              >
                <span style={{ fontSize: '14px' }}>🎙️</span>
                Start Recording
              </button>
            </div>
          )}

          {/* VOICE CLONE */}
          {current.screen === 'voice-clone' && (
            <div style={{ padding: '0 20px', position: 'relative', height: 'calc(100% - 40px)', overflow: 'hidden' }}>
              <div style={{ marginTop: '12px' }}>
                <ChevronLeft size={22} color={c.gold} strokeWidth={2} />
              </div>

              <div style={{ marginTop: '14px', display: 'flex', gap: '6px' }}>
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.gold, borderRadius: '2px' }} />
                <div style={{ flex: 1, height: '3px', background: c.borderSoft, borderRadius: '2px' }} />
              </div>

              <div style={{ marginTop: '18px', textAlign: 'center', fontSize: '26px', color: c.text, fontFamily: c.serif, fontWeight: 500 }}>
                Great Recording!
              </div>
              <div style={{ marginTop: '4px', textAlign: 'center', fontSize: '12px', color: c.textMuted, fontFamily: c.sans }}>
                Your voice clone is ready to create
              </div>

              {/* Success circle */}
              <div style={{ marginTop: '18px', display: 'flex', justifyContent: 'center' }}>
                <div style={{ width: '80px', height: '80px', borderRadius: '50%', border: `2px solid ${c.gold}`, background: c.goldSoft, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                  <Check size={22} color={c.gold} strokeWidth={2.5} />
                  <div style={{ fontSize: '13px', color: c.text, fontFamily: c.sans, fontWeight: 700, marginTop: '2px' }}>0:00</div>
                </div>
              </div>

              {/* Success banner */}
              <div style={{ marginTop: '16px', padding: '12px', background: c.greenSoft, border: `1px solid ${c.green}50`, borderRadius: '10px', textAlign: 'center' }}>
                <div style={{ fontSize: '12px', color: c.green, fontFamily: c.sans, fontWeight: 600, lineHeight: 1.4 }}>
                  Perfect! 30 seconds recorded.<br />
                  Click 'Create Clone Voice' below to continue.
                </div>
              </div>

              {/* What happens next */}
              <div style={{ marginTop: '12px', padding: '12px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '10px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: c.text, fontFamily: c.sans, fontWeight: 700 }}>
                  ✨ What happens next?
                </div>
                <div style={{ marginTop: '6px', fontSize: '11px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.4 }}>
                  Click 'Create Clone Voice' to generate your manifestation story. Takes 30 to 45 seconds.
                </div>
              </div>

              {/* Listen / Re-record */}
              <div style={{ marginTop: '12px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                <div style={{ padding: '11px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontSize: '12px', color: c.text, fontFamily: c.sans, fontWeight: 600 }}>
                  <Headphones size={12} />
                  Listen
                </div>
                <div style={{ padding: '11px', background: c.bgCard, border: `1px solid ${c.borderSoft}`, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontSize: '12px', color: c.text, fontFamily: c.sans, fontWeight: 600 }}>
                  <RefreshCw size={12} />
                  Re-record
                </div>
              </div>

              {/* Create Clone Voice */}
              <button
                style={{
                  width: '100%',
                  marginTop: '12px',
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
                  gap: '8px',
                  cursor: 'pointer',
                  boxShadow: current.target === 'clone-button' ? `0 0 0 4px ${c.gold}40, 0 0 40px ${c.gold}80` : `0 4px 14px ${c.gold}40`,
                  position: 'relative',
                  zIndex: current.target === 'clone-button' ? 35 : 1,
                  animation: current.target === 'clone-button' ? 'pulse 2s infinite' : 'none',
                }}
              >
                <Sparkles size={14} fill="#fff" />
                Create Clone Voice
              </button>
            </div>
          )}

          {/* DARKENING OVERLAY */}
          {current.target && (
            <div style={{ position: 'absolute', inset: 0, background: 'rgba(20,15,10,0.55)', zIndex: 30, pointerEvents: 'none', animation: 'fadeIn 0.3s ease' }} />
          )}

          {/* TUTORIAL CARD */}
          <div
            key={`${flow}-${step}`}
            style={{
              position: 'absolute',
              left: '20px',
              right: '20px',
              ...(current.cardPosition === 'top' && { top: '90px' }),
              ...(current.cardPosition === 'top-compact' && { top: '50px' }),
              ...(current.cardPosition === 'bottom' && { bottom: '110px' }),
              ...(current.cardPosition === 'center' && { top: '50%', transform: 'translateY(-50%)' }),
              background: c.bgCard,
              borderRadius: '20px',
              padding: '22px 20px',
              border: `1.5px solid ${c.gold}`,
              boxShadow: '0 20px 50px rgba(0,0,0,0.25), 0 0 60px rgba(184,134,47,0.2)',
              zIndex: 40,
              animation: 'slideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
          >
            {current.arrowDirection === 'down' && (
              <div style={{ position: 'absolute', bottom: '-10px', left: '50%', transform: 'translateX(-50%) rotate(45deg)', width: '18px', height: '18px', background: c.bgCard, borderRight: `1.5px solid ${c.gold}`, borderBottom: `1.5px solid ${c.gold}` }} />
            )}
            {current.arrowDirection === 'up' && (
              <div style={{ position: 'absolute', top: '-10px', left: '50%', transform: 'translateX(-50%) rotate(45deg)', width: '18px', height: '18px', background: c.bgCard, borderLeft: `1.5px solid ${c.gold}`, borderTop: `1.5px solid ${c.gold}` }} />
            )}

            {/* Progress dots */}
            <div style={{ display: 'flex', gap: '4px', marginBottom: '14px' }}>
              {tutorialSteps.map((_, i) => (
                <div key={i} style={{ height: '3px', flex: 1, background: i <= step ? c.gold : c.borderSoft, borderRadius: '2px', transition: 'background 0.3s' }} />
              ))}
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <div style={{ fontSize: '10px', color: c.gold, letterSpacing: '0.18em', textTransform: 'uppercase', fontFamily: c.sans, fontWeight: 700 }}>
                {flow === 'pre' ? 'Getting Started' : 'Voice Setup'} · {step + 1}/{tutorialSteps.length}
              </div>
              {current.isPaywall && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '9px', color: c.gold, fontFamily: c.sans, fontWeight: 700 }}>
                  <Lock size={9} />
                  PAYWALL
                </div>
              )}
            </div>

            <div style={{ fontSize: '20px', color: c.text, fontFamily: c.serif, fontWeight: 500, lineHeight: 1.2, marginBottom: '8px' }}>
              {current.title}
            </div>

            <div style={{ fontSize: '13px', color: c.textMuted, fontFamily: c.sans, lineHeight: 1.55, marginBottom: '18px' }}>
              {current.body}
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '12px' }}>
              <button onClick={handleSkip} style={{ background: 'transparent', border: 'none', color: c.textMuted, fontSize: '13px', fontFamily: c.sans, fontWeight: 500, cursor: 'pointer', padding: '8px 4px' }}>
                {current.isFinal ? 'Restart' : 'Skip all'}
              </button>
              <button onClick={handleNext} style={{ background: c.gold, border: 'none', borderRadius: '12px', color: '#fff', fontSize: '13px', fontFamily: c.sans, fontWeight: 600, padding: '11px 22px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', boxShadow: `0 4px 12px ${c.gold}40` }}>
                {current.isFinal ? (flow === 'pre' ? 'Continue to Voice' : "Let's Go") : 'Next'}
                <ChevronRight size={14} />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Side panel */}
      <div style={{ maxWidth: '320px', color: c.bg }}>
        <div style={{ fontSize: '10px', letterSpacing: '0.25em', textTransform: 'uppercase', color: c.goldLight, fontFamily: c.sans, fontWeight: 700, marginBottom: '12px' }}>
          Tutorial Walkthrough
        </div>
        <div style={{ fontSize: '36px', fontFamily: c.serif, fontWeight: 500, color: c.bg, lineHeight: 1.05, marginBottom: '8px' }}>
          Already <span style={{ fontStyle: 'italic', color: c.goldLight }}>Done</span>
        </div>
        <div style={{ fontSize: '13px', color: '#a89b85', fontFamily: c.sans, lineHeight: 1.5, marginBottom: '20px' }}>
          New user onboarding flow, designed in your real app system.
        </div>

        <div style={{ display: 'flex', gap: '6px', padding: '4px', background: 'rgba(255,255,255,0.05)', borderRadius: '12px', marginBottom: '20px' }}>
          <button onClick={() => switchFlow('pre')} style={{ flex: 1, padding: '10px', background: flow === 'pre' ? c.gold : 'transparent', border: 'none', borderRadius: '8px', color: flow === 'pre' ? '#fff' : '#a89b85', fontSize: '12px', fontFamily: c.sans, fontWeight: 600, cursor: 'pointer' }}>
            Pre-Paywall
          </button>
          <button onClick={() => switchFlow('post')} style={{ flex: 1, padding: '10px', background: flow === 'post' ? c.gold : 'transparent', border: 'none', borderRadius: '8px', color: flow === 'post' ? '#fff' : '#a89b85', fontSize: '12px', fontFamily: c.sans, fontWeight: 600, cursor: 'pointer' }}>
            Post-Paywall
          </button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {tutorialSteps.map((s, i) => (
            <button key={i} onClick={() => setStep(i)} style={{ textAlign: 'left', padding: '11px 14px', background: step === i ? `${c.gold}25` : 'rgba(255,255,255,0.03)', border: `1px solid ${step === i ? c.gold : 'rgba(255,255,255,0.06)'}`, borderRadius: '10px', color: c.bg, fontSize: '12px', fontFamily: c.sans, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px' }}>
              <span style={{ width: '20px', height: '20px', borderRadius: '50%', background: step === i ? c.gold : 'rgba(255,255,255,0.08)', color: step === i ? '#fff' : '#a89b85', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: 700, flexShrink: 0 }}>
                {i + 1}
              </span>
              <span style={{ flex: 1 }}>{s.title}</span>
              {s.isPaywall && <Lock size={11} color={c.goldLight} />}
            </button>
          ))}
        </div>
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { box-shadow: 0 0 0 4px rgba(184,134,47,0.3), 0 0 40px rgba(184,134,47,0.5); }
          50% { box-shadow: 0 0 0 8px rgba(184,134,47,0.15), 0 0 60px rgba(184,134,47,0.7); }
        }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; } }
      `}</style>
    </div>
  );
}
