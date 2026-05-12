//! Phase 0 — Candle smoke test.
//!
//! Verifies that candle-core works on both CPU and (optionally) CUDA backends.

use candle_core::{Device, Tensor, DType};

fn main() -> anyhow::Result<()> {
    for dev_label in ["cpu", "cuda"] {
        let device = match dev_label {
            "cpu" => Device::Cpu,
            "cuda" => match Device::new_cuda(0) {
                Ok(d) => d,
                Err(e) => {
                    println!("{dev_label}: SKIPPED — {e}");
                    continue;
                }
            },
            _ => unreachable!(),
        };
        let a = Tensor::randn(0f32, 1.0, (512, 512), &device)?;
        let b = Tensor::randn(0f32, 1.0, (512, 512), &device)?;
        let c = a.matmul(&b)?;
        println!("{dev_label}: matmul ok, shape={:?}", c.shape());
    }
    println!("\n✓ Smoke test passed.");
    Ok(())
}
