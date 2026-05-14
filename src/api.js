import { CODY_CONTEXT, TONE_PROMPTS, LENGTHS, HOOKS, CLOSINGS, STRUCTURES } from './constants';

const pick = arr => arr[Math.floor(Math.random() * arr.length)];

const PROXY_URL = import.meta.env.VITE_API_PROXY_URL;

export function buildPrompt({ tone, length, randomize, idea, isRegen, hasImage }) {
  const len = LENGTHS.find(l => l.value === length);
  let p = `${TONE_PROMPTS[tone]}\n\nTarget length: ${len.words}.\n`;
  if (randomize) {
    p += `\nHook: ${pick(HOOKS)}\nStructure: ${pick(STRUCTURES)}\nClosing: ${pick(CLOSINGS)}\n`;
  }
  if (hasImage) {
    p += `\nAn image has been provided. Analyze it and incorporate what you see into the post, combined with the idea below.\n`;
  }
  if (idea.trim()) {
    p += `\nIdea or topic: "${idea.trim()}"\n`;
  }
  if (isRegen) {
    p += `\nA previous version exists. Write a completely different version with a different hook, angle, and structure.\n`;
  }
  return p;
}

export async function generatePost({ tone, length, randomize, idea, isRegen, image }) {
  if (!PROXY_URL) throw new Error('Proxy URL not configured. Add VITE_API_PROXY_URL to your GitHub secrets.');

  const prompt = buildPrompt({ tone, length, randomize, idea, isRegen, hasImage: !!image });

  let messageContent;
  if (image) {
    messageContent = [
      { type: 'image', source: { type: 'base64', media_type: image.mediaType, data: image.base64 } },
      { type: 'text', text: prompt },
    ];
  } else {
    messageContent = prompt;
  }

  const res = await fetch(PROXY_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      model: 'claude-sonnet-4-6',
      max_tokens: 800,
      system: CODY_CONTEXT,
      messages: [{ role: 'user', content: messageContent }],
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message || `API error ${res.status}`);
  }

  const data = await res.json();
  const text = data.content?.filter(b => b.type === 'text').map(b => b.text).join('').trim();
  if (!text) throw new Error('Empty response. Try again.');
  return text;
}

export function compressImage(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.onload = (ev) => {
      const img = new Image();
      img.onerror = () => reject(new Error('Failed to load image'));
      img.onload = () => {
        const MAX = 1024;
        let w = img.width, h = img.height;
        if (w > MAX || h > MAX) {
          if (w > h) { h = Math.round(h * MAX / w); w = MAX; }
          else { w = Math.round(w * MAX / h); h = MAX; }
        }
        const canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;
        canvas.getContext('2d').drawImage(img, 0, 0, w, h);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.82);
        resolve({
          preview: dataUrl,
          base64: dataUrl.split(',')[1],
          mediaType: 'image/jpeg',
        });
      };
      img.src = ev.target.result;
    };
    reader.readAsDataURL(file);
  });
}
