import { describe, it, expect, vi } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('audio', () => {
  describe('transcribe', () => {
    it('transcribes an audio file', async () => {
      const mockResponse = { text: 'Hello, world!' };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const file = new Blob(['audio-data'], { type: 'audio/wav' });
      const result = await client.audio.transcribe({ file, model: 'whisper-1' });

      expect(result.text).toBe('Hello, world!');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://api.test.com/v1/audio/transcriptions');
      expect(opts.method).toBe('POST');
      expect(opts.body).toBeInstanceOf(FormData);
    });

    it('includes optional parameters in form data', async () => {
      const fetch = mockFetch({ text: 'Bonjour' });
      const client = createClient(fetch);

      const file = new Blob(['audio-data'], { type: 'audio/wav' });
      await client.audio.transcribe({
        file,
        model: 'whisper-1',
        language: 'fr',
        prompt: 'Transcribe in French',
        response_format: 'json',
        temperature: 0.2,
      });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      const formData = opts.body as FormData;
      expect(formData.get('model')).toBe('whisper-1');
      expect(formData.get('language')).toBe('fr');
      expect(formData.get('prompt')).toBe('Transcribe in French');
      expect(formData.get('response_format')).toBe('json');
      expect(formData.get('temperature')).toBe('0.2');
    });

    it('throws ValidationError when file is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(
        client.audio.transcribe({ file: null as unknown as Blob, model: 'whisper-1' }),
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when model is missing', async () => {
      const client = createClient(mockFetch({}));
      const file = new Blob(['audio-data'], { type: 'audio/wav' });
      await expect(
        client.audio.transcribe({ file, model: '' }),
      ).rejects.toThrow(ValidationError);
    });
  });
});
