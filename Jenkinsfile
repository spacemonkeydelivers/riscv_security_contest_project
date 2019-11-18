pipeline {
    agent any

    environment {
        PATH = "PATH=$PATH:/tank/work/dev/toolchains/riscv32imc-tags-newlib-gcc/bin/"
        LLVM_TOOLCHAIN_PATH = "/tank/work/dev/toolchains/riscv32imc-llvm"
    }
    stages {
        stage('Build') {
            steps {
                sh """
                  ls && \
                  cd secure_soc && \
                  update_submodules.sh && \
                  cd .. \
                  mkdir build && \
                  cd build && \
                  cmake -DRISCV_LLVM_TOOLCHAIN_PATH=${LLVM_TOOLCHAIN_PATH} ../ && \
                  make -j10
                """
            }
        }
        stage('Run debug verilated tests') {
            steps {
                sh 'cd build && ctest -LE nightly -j10'
            }
        }
    }


    post {
        always {
            cleanWs()
        }
    }
}
