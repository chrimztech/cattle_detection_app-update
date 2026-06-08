"""
YOLOv8 Training Script for Cattle Detection
-------------------------------------------
This script trains a YOLOv8 model on a custom cattle dataset 
and exports the trained model to multiple formats for deployment 
in Flutter, mobile apps, or other environments.

Requirements:
    pip install ultralytics
    pip install torch torchvision

Usage:
    python train_yolo_cattle.py
"""

import argparse
import os
from ultralytics import YOLO


def train_yolo(
    data_path: str,
    model_type: str = "yolov8n.pt",
    epochs: int = 50,
    batch_size: int = 16,
    img_size: int = 640,
    device: str = "cpu",
    workers: int = 2
):
    """
    Train a YOLOv8 model on the given dataset and export it.

    Args:
        data_path (str): Path to dataset YAML file.
        model_type (str): Base YOLOv8 model to use (e.g. 'yolov8n.pt', 'yolov8s.pt').
        epochs (int): Number of training epochs.
        batch_size (int): Batch size for training.
        img_size (int): Input image size.
        device (str): Device to use ('cpu' or '0' for GPU).
        workers (int): Number of dataloader workers.
    """
    try:
        print(f"\n🚀 Starting training with {model_type} on {device}...\n")

        # 1. Load YOLO model
        model = YOLO(model_type)

        # 2. Train model
        results = model.train(
            data=data_path,
            epochs=epochs,
            imgsz=img_size,
            batch=batch_size,
            workers=workers,
            device=device
        )

        print("\n✅ Training completed successfully!")

        # 3. Export to multiple formats
        print("\n📦 Exporting model to deployment formats...")
        model.export(format="tflite")      # TensorFlow Lite (Flutter / Android)
        model.export(format="onnx")        # ONNX (cross-platform)
        model.export(format="torchscript") # TorchScript (PyTorch mobile)

        print("\n🎉 Model exported successfully! Check the 'runs/' folder for outputs.\n")

    except Exception as e:
        print(f"❌ Error during training: {e}")


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Train YOLOv8 model on cattle dataset.")
    parser.add_argument("--data", type=str, default="cattle_dataset/data.yaml",
                        help="Path to dataset YAML file")
    parser.add_argument("--model", type=str, default="yolov8n.pt",
                        help="YOLOv8 model type (yolov8n.pt, yolov8s.pt, etc.)")
    parser.add_argument("--epochs", type=int, default=50,
                        help="Number of epochs")
    parser.add_argument("--batch", type=int, default=16,
                        help="Batch size")
    parser.add_argument("--imgsz", type=int, default=640,
                        help="Image size")
    parser.add_argument("--device", type=str, default="cpu",
                        help="Device to use: 'cpu' or '0' for GPU")
    parser.add_argument("--workers", type=int, default=2,
                        help="Number of dataloader workers")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    train_yolo(
        data_path=args.data,
        model_type=args.model,
        epochs=args.epochs,
        batch_size=args.batch,
        img_size=args.imgsz,
        device=args.device,
        workers=args.workers
    )
