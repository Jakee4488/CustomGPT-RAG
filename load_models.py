
import torch
from auto_gptq import AutoGPTQForCausalLM
from huggingface_hub import hf_hub_download
from langchain.llms import LlamaCpp

from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    LlamaForCausalLM,
    LlamaTokenizer,
)
from constants import (
    CONTEXT_WINDOW_SIZE, 
    MAX_NEW_TOKENS, 
    N_GPU_LAYERS, 
    N_BATCH
)



def load_quantized_model_qptq(model_id, model_basename, device_type, logging):

    """
    Load a GPTQ quantized model using AutoGPTQForCausalLM.

    This function loads a quantized model that ends with GPTQ and may have variations 
    of .no-act.order or .safetensors in their HuggingFace repo.

    Parameters:
    - model_id (str): The identifier for the model on HuggingFace Hub.
    - model_basename (str): The base name of the model file.
    - device_type (str): The type of device where the model will run.
    - logging (logging.Logger): Logger instance for logging messages.

    Returns:
    - model (AutoGPTQForCausalLM): The loaded quantized model.
    - tokenizer (AutoTokenizer): The tokenizer associated with the model.

    Notes:
    - The function checks for the ".safetensors" ending in the model_basename and removes it if present.
    """
        
    # The code supports all huggingface models that ends with GPTQ and have some variation
    # of .no-act.order or .safetensors in their HF repo.
    logging.info("Using AutoGPTQForCausalLM for quantized models")

    if ".safetensors" in model_basename:
        # Remove the ".safetensors" ending if present
        model_basename = model_basename.replace(".safetensors", "")

    tokenizer = AutoTokenizer.from_pretrained(model_id, use_fast=True)
    logging.info("Tokenizer loaded")

    model = AutoGPTQForCausalLM.from_quantized(
        model_id,
        model_basename=model_basename,
        use_safetensors=True,
        trust_remote_code=True,
        device_map="auto",
        use_triton=False,
        quantize_config=None,
    )
    return model, tokenizer

