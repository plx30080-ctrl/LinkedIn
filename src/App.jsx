import { useState, useRef, useEffect } from 'react';
import { TONES, LENGTHS, QUEUE_KEY, API_KEY_STORAGE } from './constants';
import { generatePost, compressImage } from './api';
import './App.css';

function LoadingDots() {
  return (
    <span className="dots">
      <span>.</span><span>.</span><span>.</span>
    </span>
  );
}

export default function App() {
  const [apiKey, setApiKey] = useState('');
  const [apiKeyInput, setApiKeyInput] = useState('');
  const [keySaved, setKeySaved] = useState(false);

  const [idea, setIdea] = useState('');
  const [tone, setTone] = useState('practical');
  const [length, setLength] = useState('medium');
  const [randomize, setRandomize] = useState(true);
  const [image, setImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);

  const [draft, setDraft] = useState('');
  const [hadResult, setHadResult] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [queue, setQueue] = useState([]);
  const [tab, setTab] = useState('create');
  const [copied, setCopied] = useState(null);

  const taRef = useRef(null);
  const fileRef = useRef(null);

  useEffect(() => {
    try {
      const q = localStorage.getItem(QUEUE_KEY);
      if (q) setQueue(JSON.parse(q));
      const k = localStorage.getItem(API_KEY_STORAGE);
      if (k) setApiKey(k);
    } catch (e) {}
  }, []);

  useEffect(() => {
    if (draft && taRef.current) {
      taRef.current.style.height = 'auto';
      taRef.current.style.height = taRef.current.scrollHeight + 'px';
    }
  }, [draft]);

  const persist = (q) => {
    setQueue(q);
    try { localStorage.setItem(QUEUE_KEY, JSON.stringify(q)); } catch (e) {}
  };

  const saveKey = () => {
    if (!apiKeyInput.trim()) return;
    localStorage.setItem(API_KEY_STORAGE, apiKeyInput.trim());
    setApiKey(apiKeyInput.trim());
    setKeySaved(true);
    setTimeout(() => setKeySaved(false), 2000);
  };

  const clearKey = () => {
    localStorage.removeItem(API_KEY_STORAGE);
    setApiKey('');
    setApiKeyInput('');
  };

  const handleImage = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    try {
      const compressed = await compressImage(file);
      setImagePreview(compressed.preview);
      setImage({ base64: compressed.base64, mediaType: compressed.mediaType });
    } catch (err) {
      setError('Failed to process image. Try a different file.');
    }
  };

  const clearImage = () => {
    setImage(null);
    setImagePreview(null);
    if (fileRef.current) fileRef.current.value = '';
  };

  const run = async (isRegen) => {
    if (!apiKey) { setError('Add your API key in the Settings tab first.'); return; }
    if (!idea.trim() && !image) return;
    setLoading(true);
    setError('');
    if (!isRegen) { setDraft(''); setHadResult(false); }
    try {
      const text = await generatePost({ apiKey, tone, length, randomize, idea, isRegen, image });
      setDraft(text);
      setHadResult(true);
    } catch (err) {
      setError(err.message || 'Something went wrong. Try again.');
    } finally {
      setLoading(false);
    }
  };

  const enqueue = () => {
    if (!draft.trim()) return;
    const post = {
      id: Date.now(),
      content: draft,
      idea,
      tone,
      length,
      status: 'queued',
      date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    };
    persist([post, ...queue]);
    setTab('queue');
  };

  const cp = (text, id) => {
    navigator.clipboard.writeText(text);
    setCopied(id);
    setTimeout(() => setCopied(null), 2000);
  };

  const wc = t => t.trim().split(/\s+/).filter(Boolean).length;
  const queuedCount = queue.filter(p => p.status === 'queued').length;
  const canGenerate = !loading && (idea.trim() || image) && apiKey;

  return (
    <div className="app">
      <header className="hdr">
        <div className="hdr-eye">LinkedIn Content Tool</div>
        <div className="hdr-title">Post <span>Smarter,</span> Not More</div>
        <div className="hdr-sub">Drop an idea. Get a post. Approve and queue it.</div>
      </header>

      <nav className="tabs">
        <button className={`tab ${tab === 'create' ? 'on' : ''}`} onClick={() => setTab('create')}>Create</button>
        <button className={`tab ${tab === 'queue' ? 'on' : ''}`} onClick={() => setTab('queue')}>
          Queue {queuedCount > 0 && <span className="bdg">{queuedCount}</span>}
        </button>
        <button className={`tab ${tab === 'settings' ? 'on' : ''}`} onClick={() => setTab('settings')}>
          Settings {!apiKey && <span className="bdg alert">!</span>}
        </button>
      </nav>

      {tab === 'create' && (
        <div className="pane">
          <div className="fld">
            <div className="lbl">Your Idea</div>
            <textarea
              className="ta"
              rows={3}
              placeholder="A win, a frustration, something you built, a lesson learned, anything..."
              value={idea}
              onChange={e => setIdea(e.target.value)}
            />
          </div>

          <div className="fld">
            <div className="lbl">Image (optional)</div>
            <div className={`img-zone ${image ? 'filled' : ''}`}>
              {image ? (
                <div className="img-preview">
                  <img src={imagePreview} className="img-thumb" alt="upload preview" />
                  <div className="img-info">
                    <div className="img-meta">Image loaded. Post will incorporate what the AI sees.</div>
                    <button className="img-clear" onClick={clearImage}>Remove</button>
                  </div>
                </div>
              ) : (
                <>
                  <label className="img-btn" htmlFor="img-upload">+ Upload Image</label>
                  <input
                    id="img-upload"
                    ref={fileRef}
                    type="file"
                    accept="image/jpeg,image/png,image/gif,image/webp"
                    style={{ display: 'none' }}
                    onChange={handleImage}
                  />
                  <div className="img-hint">JPG, PNG, GIF, WEBP. Compressed automatically before sending.</div>
                </>
              )}
            </div>
          </div>

          <div className="two-col">
            <div className="fld">
              <div className="lbl">Tone</div>
              <div className="pills">
                {TONES.map(t => (
                  <button key={t.value} className={`pill ${tone === t.value ? 'on' : ''}`} onClick={() => setTone(t.value)}>
                    {t.label}
                  </button>
                ))}
              </div>
              <div className="hint">{TONES.find(t => t.value === tone)?.desc}</div>
            </div>
            <div className="fld">
              <div className="lbl">Length</div>
              <div className="pills">
                {LENGTHS.map(l => (
                  <button key={l.value} className={`pill ${length === l.value ? 'on' : ''}`} onClick={() => setLength(l.value)}>
                    {l.label}
                  </button>
                ))}
              </div>
              <div className="hint">{LENGTHS.find(l => l.value === length)?.desc}</div>
            </div>
          </div>

          <div className="tog-row">
            <label className="tog">
              <input type="checkbox" checked={randomize} onChange={e => setRandomize(e.target.checked)} />
              <div className="trk"></div>
              <div className="thm"></div>
            </label>
            <span className={`tog-lbl ${randomize ? 'on' : ''}`}>
              Randomize hook + structure: {randomize ? 'on' : 'off'}
            </span>
          </div>

          <div className="btns">
            <button className="btn btn-blue" onClick={() => run(false)} disabled={!canGenerate}>
              {loading ? 'Generating...' : 'Generate Post'}
            </button>
            {hadResult && !loading && (
              <button className="btn btn-ghost" onClick={() => run(true)} disabled={loading}>
                Try Again
              </button>
            )}
          </div>

          {!apiKey && (
            <div className="warn">Add your Anthropic API key in Settings to get started.</div>
          )}

          {error && <div className="err">{error}</div>}

          {loading && (
            <div className="spin">
              <LoadingDots />
              <span>Writing your post</span>
            </div>
          )}

          {hadResult && !loading && (
            <>
              <hr className="hr" />
              <div className="lbl">Edit Before Queuing</div>
              <div className="draft-box">
                <div className="draft-hdr">
                  <span className="lbl" style={{ marginBottom: 0 }}>Draft</span>
                  <span className="wc">{wc(draft)} words</span>
                </div>
                <textarea
                  ref={taRef}
                  className="draft-ta"
                  value={draft}
                  onChange={e => setDraft(e.target.value)}
                />
              </div>
              <div className="btns" style={{ marginTop: 12 }}>
                <button className="btn btn-grn" onClick={enqueue} disabled={!draft.trim()}>
                  Add to Queue
                </button>
                <button
                  className={`btn btn-ghost ${copied === 'draft' ? 'flash' : ''}`}
                  onClick={() => cp(draft, 'draft')}
                >
                  {copied === 'draft' ? 'Copied!' : 'Copy Post'}
                </button>
              </div>
            </>
          )}
        </div>
      )}

      {tab === 'queue' && (
        <div className="pane">
          {queue.length === 0 ? (
            <div className="empty">
              <div className="empty-ico">📭</div>
              <div className="empty-lbl">Queue is empty</div>
              <div className="empty-sub">Generate a post and add it here</div>
            </div>
          ) : (
            <div className="q-list">
              {queue.map(post => (
                <div key={post.id} className={`q-card ${post.status === 'posted' ? 'posted' : ''}`}>
                  <div className="q-head">
                    <div className="q-meta">
                      <span className={`tag ${post.status === 'posted' ? 'green' : ''}`}>
                        {post.status === 'posted' ? 'Posted' : 'Queued'}
                      </span>
                      <span className="tag">{TONES.find(t => t.value === post.tone)?.label}</span>
                      <span className="tag">{LENGTHS.find(l => l.value === post.length)?.label}</span>
                    </div>
                    <div className="q-right">
                      <span className="q-date">{post.date}</span>
                      <div className="q-actions">
                        <button
                          className={`btn btn-ghost btn-sm ${copied === post.id ? 'flash' : ''}`}
                          onClick={() => cp(post.content, post.id)}
                        >
                          {copied === post.id ? 'Copied!' : 'Copy'}
                        </button>
                        {post.status !== 'posted' && (
                          <button
                            className="btn btn-grn btn-sm"
                            onClick={() => persist(queue.map(p => p.id === post.id ? { ...p, status: 'posted' } : p))}
                          >
                            Mark Posted
                          </button>
                        )}
                        <button
                          className="btn btn-ghost btn-sm"
                          onClick={() => persist(queue.filter(p => p.id !== post.id))}
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  </div>
                  <div className="q-body">{post.content}</div>
                  {post.idea && <div className="q-idea">Idea: {post.idea}</div>}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {tab === 'settings' && (
        <div className="pane">
          <div className="lbl">Anthropic API Key</div>
          <p className="settings-note">
            Saved to your browser only. Never sent anywhere except Anthropic's API directly.
            Get one at <a href="https://console.anthropic.com" target="_blank" rel="noreferrer">console.anthropic.com</a>.
            Each post costs roughly $0.003.
          </p>
          {apiKey ? (
            <div>
              <div className="key-saved">
                <span className="key-label">Key saved</span>
                <span className="key-val">{apiKey.slice(0, 16)}...</span>
              </div>
              <button className="btn btn-ghost" onClick={clearKey}>Remove Key</button>
            </div>
          ) : (
            <div>
              <input
                type="password"
                className="key-input"
                placeholder="sk-ant-api03-..."
                value={apiKeyInput}
                onChange={e => setApiKeyInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && saveKey()}
              />
              <button className="btn btn-blue" onClick={saveKey} disabled={!apiKeyInput.trim()} style={{ marginTop: 10 }}>
                {keySaved ? 'Saved!' : 'Save Key'}
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
