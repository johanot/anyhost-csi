use std::env;
use std::path::Path;

fn main() -> anyhow::Result<()> {
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let out_dir = Path::new(&out_dir);

    let csi = out_dir.join("csi");
    std::fs::create_dir_all(&csi)?;

    let data = include_bytes!("csi.proto");
    let proto = csi.join("csi.proto");
    std::fs::write(&proto, data)?;

    tonic_build::configure()
        .build_server(true)
        .emit_rerun_if_changed(false)
        .compile_protos(&[proto], &[csi])?;

    println!("cargo:rerun-if-changed=build.rs");

    Ok(())
}
