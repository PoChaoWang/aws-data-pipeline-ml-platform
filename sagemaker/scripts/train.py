
import argparse
import os
import pandas as pd
from sklearn.cluster import KMeans
import joblib

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # Hyperparameters
    parser.add_argument('--n-clusters', type=int, default=5)

    # SageMaker environment variables
    parser.add_argument('--output-data-dir', type=str, default=os.environ.get('SM_OUTPUT_DATA_DIR'))
    parser.add_argument('--model-dir', type=str, default=os.environ.get('SM_MODEL_DIR'))
    parser.add_argument('--train', type=str, default=os.environ.get('SM_CHANNEL_TRAIN'))

    args = parser.parse_args()

    print("Starting training job")

    # Load training data
    try:
        input_file = os.path.join(args.train, 'train.csv')
        df = pd.read_csv(input_file, header=None)
    except Exception as e:
        print("Error loading training data:", e)
        # Exit if data is not found
        sys.exit(1)

    # Train the model (KMeans in this example)
    kmeans = KMeans(n_clusters=args.n_clusters)
    kmeans.fit(df)

    # Save the trained model
    model_path = os.path.join(args.model_dir, "model.joblib")
    joblib.dump(kmeans, model_path)

    print(f"Model saved to {model_path}")
    print("Finished training job")

# --- For Inference ---

def model_fn(model_dir):
    """Loads the model from the disk."""
    model = joblib.load(os.path.join(model_dir, "model.joblib"))
    return model

def input_fn(request_body, request_content_type):
    """Deserializes the input data."""
    if request_content_type == 'text/csv':
        return pd.read_csv(io.StringIO(request_body), header=None).values
    else:
        raise ValueError(f"Unsupported content type: {request_content_type}")

def predict_fn(input_data, model):
    """Makes a prediction."""
    return model.predict(input_data)

def output_fn(prediction, response_content_type):
    """Serializes the prediction output."""
    if response_content_type == 'application/json':
        return json.dumps(prediction.tolist())
    else:
        raise ValueError(f"Unsupported content type: {response_content_type}")
