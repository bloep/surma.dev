#!/bin/bash

OUTPUT=${OUTPUT:-"results.csv"}
echo "Writing to $OUTPUT"

PROGRAMS=${PROGRAMS:-"blur bubblesort binaryheap"}
VERSIONS=${VERSIONS:-"naive idiomatic optimized"}
RUNTIMES=${RUNTIMES:-"stub minimal incremental"}
OPTIMIZERS=${OPTIMIZERS:-"O3 O3s"}

echo "Program,Language,Engine,Variant,Optimizer,Runtime" > $OUTPUT

for program in $PROGRAMS ; do
  if [ -f "${program}.js" ]; then
    # JavaScript
    if [ -z "${SKIP_JS}" ]; then
      echo -n "${program},JavaScript,Ignition,optimized,,," | tee -a $OUTPUT
      v8 --no-opt --module --harmony-top-level-await ./${program}_js_bench.js >> $OUTPUT
      echo "" 
      echo -n "${program},JavaScript,Turbofan,optimized,,," | tee -a $OUTPUT
      v8 --module --harmony-top-level-await ./${program}_js_bench.js >> $OUTPUT
      echo "" 
    fi
  fi
  # AssemblyScript
  for version in $VERSIONS; do
    for runtime in $RUNTIMES; do
      for optimizer in $OPTIMIZERS; do
        SRCFILE="${program}_${version}.ts"
        FILE="./${program}_${version}_${optimizer}_${runtime}.wasm"
        if [ -f $SRCFILE ] && [ -z "${SKIP_ASC}" ]; then
          echo "Creating ${FILE}"
          npx asc -b ${program}_${version}_${optimizer}_${runtime}.wasm --runtime ${runtime} -${optimizer} --enable bulk-memory ${SRCFILE}
        fi
        if [ -z "${COMPILE_ONLY}" ] && [ -z "${SKIP_ASC}" ]; then
          if [ -f $FILE ]; then
            echo -n "${program},AssemblyScript,Liftoff,${version},${optimizer},${runtime}," | tee -a $OUTPUT
            v8 --liftoff-only --module --harmony-top-level-await ./${program}_asc_bench.js -- $FILE >> $OUTPUT
            echo ""
            echo -n "${program},AssemblyScript,Turbofan,${version},${optimizer},${runtime}," | tee -a $OUTPUT
            v8 --no-liftoff --no-wasm-tier-up --module --harmony-top-level-await ./${program}_asc_bench.js -- $FILE >> $OUTPUT
            echo ""
          fi
        fi
      done
    done
  done
  # Rust
  for version in $VERSIONS; do
    SRCFILE="${program}_${version}.rs"
    FILE="./${program}_${version}_rs.wasm"
    if [ -f $SRCFILE ] && [ -z "${SKIP_RUST}" ]; then
      cargo +nightly build --target wasm32-unknown-unknown --release --features ${version} 
      wasm-opt -O3 target/wasm32-unknown-unknown/release/binaryheap.wasm -o ${FILE}
      echo -n "${program},Rust,Liftoff,${version},,," | tee -a $OUTPUT
      v8 --liftoff-only --module --harmony-top-level-await ./${program}_asc_bench.js -- $FILE >> $OUTPUT
      echo ""
      echo -n "${program},Rust,Turbofan,${version},,," | tee -a $OUTPUT
      v8 --no-liftoff --no-wasm-tier-up --module --harmony-top-level-await ./${program}_asc_bench.js -- $FILE >> $OUTPUT
      echo ""
    fi
  done
done