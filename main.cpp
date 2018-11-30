#include <iostream>

#include <dlfcn.h>

using namespace std;

int main() {
  cout << "Hello World!" << endl;
#ifdef DYNAMIC_DEEPBIND
  if (!dlopen("./libshared1.so", RTLD_NOW | RTLD_DEEPBIND | RTLD_GLOBAL))
    cout << "Loading shared1 failed" << endl;
  if (!dlopen("./libshared2.so", RTLD_NOW | RTLD_DEEPBIND | RTLD_GLOBAL))
    cout << "Loading shared2 failed" << endl;
#else
  cout << "Skipping dlopen" << endl;
#endif
  return 0;
}
