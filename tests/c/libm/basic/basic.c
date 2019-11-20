#include <stdio.h>
#include <math.h>

int main () {
  double cos_d = cos(.0f);
  // double acos_d = acos(3.3f);
  double sqrt_d = sqrt(16.f);
  double pow_d = pow(4, 2);

  fprintf(stdout,
          "cos(0) as int = %d\n"
     //     "acos(3.3) as int = %d\n"
          "sqrt(16.f) as int = %d\n"
          "pow(4,2) as int = %d\n",
          (int)cos_d,
    //      (int)acos_d,
          (int)sqrt_d,
          (int)pow_d);
  return 0;
}
