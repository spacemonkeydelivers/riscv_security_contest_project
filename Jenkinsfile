pipeline {
    agent any

    environment {
        PATH = "PATH=$PATH:/tank/work/dev/toolchains/riscv32imc-tags-newlib-gcc/bin/"
    }
    stages {
        stage('Build') {
            steps {
                sh 'mkdir build && cd build && cmake -DRISCV_LLVM_TOOLCHAIN_PATH=/tank/work/dev/toolchains/riscv32imc-llvm/ ../ && make -j10'
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
