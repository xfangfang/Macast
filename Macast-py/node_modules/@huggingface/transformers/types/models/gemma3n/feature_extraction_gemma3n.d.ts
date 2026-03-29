export class Gemma3nAudioFeatureExtractor extends FeatureExtractor {
    constructor(config: any);
    mel_filters: number[][];
    window: Float64Array<ArrayBufferLike>;
    /**
     * Computes the log-Mel spectrogram of the provided audio waveform.
     * @param {Float32Array|Float64Array} waveform The audio waveform to process.
     * @param {number} max_length The maximum number of frames to return.
     * @returns {Promise<Tensor>} An object containing the log-Mel spectrogram data as a Float32Array and its dimensions as an array of numbers.
     */
    _extract_fbank_features(waveform: Float32Array | Float64Array, max_length: number): Promise<Tensor>;
    /**
     * Asynchronously extracts features from a given audio using the provided configuration.
     * @param {Float32Array|Float64Array} audio The audio data as a Float32Array/Float64Array.
     * @param {Object} options Optional parameters for feature extraction.
     * @param {number} [options.max_length=480_000] If provided, defines the maximum length of the audio to allow.
     * Audio longer than this will be truncated if `truncation=True`.
     * @param {boolean} [options.truncation=true] Whether or not to truncate audio above `max_length`.
     * @param {boolean} [options.padding=true] Whether to pad the sequence to a multiple of `pad_to_multiple_of`.
     * @param {number} [options.pad_to_multiple_of=128] The number to pad the sequence to a multiple of.
     * @returns {Promise<{ input_features: Tensor, input_features_mask: Tensor }>} A Promise resolving to an object containing the extracted input features and attention masks as Tensors.
     */
    _call(audio: Float32Array | Float64Array, { max_length, truncation, padding, pad_to_multiple_of, }?: {
        max_length?: number;
        truncation?: boolean;
        padding?: boolean;
        pad_to_multiple_of?: number;
    }): Promise<{
        input_features: Tensor;
        input_features_mask: Tensor;
    }>;
}
import { FeatureExtractor } from '../../base/feature_extraction_utils.js';
import { Tensor } from '../../utils/tensor.js';
//# sourceMappingURL=feature_extraction_gemma3n.d.ts.map