
import os
import json
import io
import pandas as pd
import joblib

def model_fn(model_dir):
    """Loads the model from the disk."""
    try:
        model = joblib.load(os.path.join(model_dir, "model.joblib"))
        return model
    except Exception as e:
        print(f"Error loading model: {e}")
        return None

def input_fn(request_body, request_content_type):
    """Deserializes the input data from an inference request."""
    if request_content_type == 'text/csv':
        return pd.read_csv(io.StringIO(request_body), header=None).values
    else:
        raise ValueError(f"Unsupported content type: {request_content_type}")

def predict_fn(input_data, model):
    """Makes a prediction on the input data."""
    if model is None:
        raise ValueError("Model not loaded")
    return model.predict(input_data)

def output_fn(prediction, response_content_type):
    """Serializes the prediction output to the desired response format."""
    if response_content_type == 'application/json':
        return json.dumps(prediction.tolist())
    else:
        raise ValueError(f"Unsupported content type: {response_content_type}")
