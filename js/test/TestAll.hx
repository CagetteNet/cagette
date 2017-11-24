package test;

import js.Browser;
import utest.Runner;
import utest.ui.Report;
import test.utils.TestCartUtils;

class TestAll
{
  public static function main()
  {
    var runner = new Runner();

    // Utils
    runner.addCase(new TestCartUtils());

    Report.create(runner);
    runner.run();
  }
}
