# LineageOS for Sony Xperia XZ1 Compact (lilac)

## How to build LineageOS

### Initial setup

* Make a workspace:

    ```bash
    mkdir -p ~/lineageos
    cd ~/lineageos
    ```

    Or use a subfolder for a specific version of LineageOS in a root folder, e.g.

    ```bash
    mkdir -p /lineageos/repo17
    cd /lineageos/repo17
    ```

* Initialize the repo:


    ```bash
    repo init -u git://github.com/LineageOS/android.git -b lineage-17.1
    ```

    Instead of `lineage-17.1` one can also use `lineage-18.1` or `lineage-19.1`
    for a different LineageOS version.

* Create local manifests, e.g. by checking out a copy of this project and symlinking the files from the appropriate folder according to the LineageOS version used:

    ```bash
    git clone https://github.com/Flamefire/lineageos_lilac.git
    mkdir .repo/local_manifests
    cd .repo/local_manifests
    ln -s ../../lineageos_lilac/manifests/17.1/*.xml .
    cd -
    ```

* Sync the repo:

    ```bash
    repo sync
    ```

### Build procedure

* Get newer Clang compiler(s)

    LineageOS 17 & 18 **only**!
    Skip this step when building a newer LineageOS.

    For better performance/battery life, we use a newer version of the Clang compiler.
    So e.g. for the kernel you need to get the folder `r416183b1` (at the time of writing) into `prebuilts/clang/host/linux-x86`.
    You can check other branches (e.g. for `r416183b1` the branch is `android-12.1.0_r22`) and checkout only that folder or otherwise copy or symlink it from anywhere into `prebuilts/clang/host/linux-x86`.

    To simplify/automate this you can copy/symlink the [clang-update-17.1.xml](manifests/clang-update-17.1.xml) manifest to your `.repo/local_manifests` (or the corresponding [file for LOS 18](manifests/clang-update-18.1.xml)) and do another `repo sync`.
    
    The `make` below will abort with a more or less descriptive error if you miss this, so just try.

    This also requires applying at least these patches in `device/sony/lilac/patches`:

    - `allow-newer-kernel-clang.patch`
    - `update-kernel-clang-for-host-cc.patch`
    
    Alternatively you can comment out the `TARGET_KERNEL_CLANG_VERSION :=` line in `device/sony/yoshino-common/BoardConfigPlatform.mk`.

* Copy [dumped firmware blobs](dump-stock.md) into place for the build

    ```bash
    cd device/sony/lilac
    ./extract-files.sh /path/to/dumped/firmware
    ```

    We currently use the latest Sony stock, which is `47.2.A.11.228`, so the file will be named like `G8441_*_47.2.A.11.228-*`.

* (Semi-)optionally apply patches

    Some of the patches in this repo fix a few bugs or issues in LineageOS while others make the build deviate a lot from the "vanilla build".
    So this is only for advanced users!

    ```bash
    device/sony/lilac/patches/applyPatches.sh
    ```

* Setup the environment

    ```bash
    source build/envsetup.sh
    lunch lineage_lilac-userdebug
    ```

* Build LineageOS

    ```bash
    mka bacon
    ```
When completed, the built files will be in the `out/target/product/lilac` directory.

### Helper scripts

To simplify the build process I use scripts which are in the [build_scripts](build_scripts) folder, so you can simply run [`build.sh`](build_scripts/build.sh).
They have some assumptions specific to my setup (such as absolute paths) in [`setup.sh`](build_scripts/setup.sh) which may need adjustments for you.
The main [build script](build_scripts/buildAndChecksum.sh) has some additional steps and checks to avoid mistakes in the semi-automated build, but does mostly what is outlined above.
