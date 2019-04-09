cargo build --release --bin new_constrained
cargo build --release --bin new
cargo build --release --bin compute_constrained
cargo build --release --bin compute # Raises error: no bin target named `compute`
cargo build --release --bin beacon # Raises error: no bin target named `beacon`
cargo build --release --bin verify_transform # Raises error: no bin target named `verify_transform`
cargo build --release --bin beacon_constrained
cargo build --release --bin verify_transform_constrained
