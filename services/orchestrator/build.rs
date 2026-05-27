// build.rs — Compiles proto\tempest.proto into Rust gRPC code at cargo build time.
// tonic_build reads proto\tempest.proto and writes generated Rust structs + gRPC
// service stubs into OUT_DIR (set automatically by Cargo).  The orchestrator's
// service modules include! those generated files at compile time.
//
// If the proto changes, just run `cargo build` again — tonic_build detects the
// change via cargo:rerun-if-changed and regenerates automatically.
fn main() {
    // Tell Cargo: if this file changes, re-run build.rs.
    println!("cargo:rerun-if-changed=../../proto/tempest.proto");

    tonic_build::configure()
        // Emit builder methods on every generated message (used in §7 orchestrator).
        .build_server(true)
        .build_client(true)
        // Write generated files to OUT_DIR (Cargo sets this automatically).
        .compile(
            &["../../proto/tempest.proto"],  // proto sources
            &["../../proto"],                 // include path (for imports)
        )
        .unwrap_or_else(|e| panic!("tonic_build failed to compile tempest.proto: {}", e));
}
