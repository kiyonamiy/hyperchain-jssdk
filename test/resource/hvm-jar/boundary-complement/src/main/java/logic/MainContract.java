package logic;

import java.math.BigInteger;
import java.util.Map;

import cn.hyperchain.annotations.StoreField;
import cn.hyperchain.core.Logger;
import cn.hyperchain.contract.BaseContract;

public class MainContract extends BaseContract {
    private static Logger logger = Logger.getLogger(MainContract.class);

    @StoreField
    int number = 5;

    // gasUsed: 41746 // gasUsed: 71763
    public int addView() {
      int new_number = 0;
      for (int i = 0; i < 1000; i ++) {
        new_number += number;
      }
      return new_number;
    }

    public int getX(int xTmp) {
        return xTmp;
    }

    public int getX() {
        return number;
    }

    public int sum(int a, int b, int c) {
      return a + b + c;
    }

    public BigInteger testBigInt(BigInteger num) {
      return num;
    }

    public String testmap(Map<String, String> map) {
      StringBuilder data = new StringBuilder();
      for (Map.Entry entry : map.entrySet()) {
        data.append("key: ");
        data.append(entry.getKey());
        data.append("value: ");
        data.append((entry.getValue()));
      }
      return data.toString();
    }
}
