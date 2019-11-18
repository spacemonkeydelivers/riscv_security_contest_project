pipeline {
    agent any

    environment {
        PATH = "PATH=$PATH:/tank/work/dev/toolchains/riscv32imc-tags-newlib-gcc/bin/"
        LLVM_TOOLCHAIN_PATH = "/tank/work/dev/toolchains/riscv32imc-llvm"
        GIT_SSH_COMMAND = 'ssh -i /home/jenkins/.ssh/id_rsa'
    }
    stages {
        stage('Build') {
            steps {
                withCredentials(usernamePassword(credentialsId: GIT_CREDS, passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME'){
                    sh """
                      git config --global credential.username {GIT_USERNAME}
                      git config --global credential.helper "!echo password={GITPASSWORD}; echo"
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
