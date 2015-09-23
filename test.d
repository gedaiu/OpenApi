import dub_test_root; //import the list of all modules
import tested;


void main() {
  assert(runUnitTests!allModules(new PrettyConsoleTestResultWriter), "Unit tests failed.");
}
