pipeline {
    agent any

    environment {
        PATH = "PATH=$PATH:/tank/work/dev/toolchains/riscv32imc-tags-newlib-gcc/bin/"
        LLVM_TOOLCHAIN_PATH = "/tank/work/dev/toolchains/riscv32imc-llvm"
        GIT_SSH_COMMAND = 'ssh -i /home/jenkins/.ssh/id_rsa'
    }
    stages {
        stage('Build') {
            timeout(time: 60, unit: 'MINUTES') {
                steps {
                    sh """
                      git submodule init && \
                      git submodule update --recursive && \
                      echo "ok" > .updated_marker && \
                      mkdir build && \
                      cd build && \
                      cmake -DRISCV_LLVM_TOOLCHAIN_PATH=${LLVM_TOOLCHAIN_PATH} ../ && \
                      make -j10
                    """
                }
            }
        }
        stage('Run debug verilated tests') {
            timeout(time: 60, unit: 'MINUTES') {
                steps {
                    sh 'cd build && ctest -LE nightly -j10'
                }
            }
        }
    }


    post {
        always {
            cleanWs()
        }
    }
}
