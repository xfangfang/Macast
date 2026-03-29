export class Gemma3nProcessor extends Processor {
    static image_processor_class: typeof AutoImageProcessor;
    static feature_extractor_class: typeof AutoFeatureExtractor;
    static tokenizer_class: typeof AutoTokenizer;
    constructor(config: any, components: any, chat_template: any);
    audio_seq_length: any;
    image_seq_length: any;
    audio_token_id: any;
    boa_token: any;
    audio_token: any;
    full_audio_sequence: string;
    image_token_id: any;
    boi_token: any;
    image_token: any;
    full_image_sequence: string;
    /**
     *
     * @param {string|string[]} text
     * @param {RawImage|RawImage[]|RawImage[][]} images
     * @param {RawAudio|RawAudio[]|RawAudio[][]} audio
     * @returns {Promise<any>}
     */
    _call(text: string | string[], images?: RawImage | RawImage[] | RawImage[][], audio?: RawAudio | RawAudio[] | RawAudio[][], options?: {}): Promise<any>;
}
import { Processor } from "../../base/processing_utils.js";
import { RawImage } from "../../utils/image.js";
import { RawAudio } from "../../utils/audio.js";
import { AutoImageProcessor } from "../auto/image_processing_auto.js";
import { AutoFeatureExtractor } from "../auto/feature_extraction_auto.js";
import { AutoTokenizer } from "../../tokenizers.js";
//# sourceMappingURL=processing_gemma3n.d.ts.map