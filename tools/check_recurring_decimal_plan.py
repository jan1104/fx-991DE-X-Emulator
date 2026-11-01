"""Validate planning data by closed-form fractions; never test calculator code.

No long division or calculator import is used. Each supplied expansion is
reconstructed as I + A/10**m + B/(10**m * (10**n - 1)).
"""

from fractions import Fraction
import json
from pathlib import Path
import re


PLAN = (Path(__file__).resolve().parents[1] / "tests" / "reference" /
        "formatting" / "recurring_decimal_planned.json")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def check_case(case):
    label = case["id"]

    def check(condition, message):
        require(condition, f"{label}: {message}")

    check(case["status"] == "planned", "must remain planned")
    check(case["evidence"] == "ownMathematicalEvidence", "independent evidence")
    source = case["input"]
    for name in ("numerator", "denominator"):
        check(isinstance(source[name], str) and
              re.fullmatch(r"-?(0|[1-9][0-9]*)", source[name]),
              f"{name} must be an integer string")
    check(int(source["denominator"]) != 0, "nonzero denominator required")
    value = Fraction(int(source["numerator"]), int(source["denominator"]))
    c = case["components"]
    check(type(c["sign"]) is int and c["sign"] in (-1, 0, 1), "invalid sign")
    check(c["sign"] == (1 if value > 0 else -1 if value < 0 else 0),
          "sign disagrees with value")
    check(re.fullmatch(r"0|[1-9][0-9]*", c["integerPart"]) is not None,
          "noncanonical integer part")
    for name in ("preperiod", "period"):
        check(isinstance(c[name], str) and
              re.fullmatch(r"[0-9]*", c[name]) is not None, "invalid digits")
    a, b = c["preperiod"], c["period"]
    if value == 0:
        check(c["integerPart"] == "0" and not a and not b,
              "zero must have empty fractional components")
    reconstructed = Fraction(int(c["integerPart"]))
    if a:
        reconstructed += Fraction(int(a), 10 ** len(a))
    if b:
        check(not a or a[-1] != b[-1], "preperiod is not minimal")
        check(any(d != "0" for d in b) and any(d != "9" for d in b),
              "noncanonical zero/nines period")
        check(not any(len(b) % n == 0 and b == b[:n] * (len(b) // n)
                      for n in range(1, len(b))), "period is not minimal")
        reconstructed += Fraction(int(b), 10 ** len(a) * (10 ** len(b) - 1))
    else:
        check(not a.endswith("0"), "finite expansion has trailing zeros")
    reconstructed *= c["sign"]
    check(reconstructed == value, "closed-form expansion differs from input")
    sign = "-" if c["sign"] < 0 else ""
    ideal = sign + c["integerPart"]
    if a or b:
        ideal += "," + a + (f"({b})" if b else "")
    check(case["unlimitedText"] == ideal, "notation/components disagree")
    digits = len(a) + len(b)
    check(case["requiredGeneratedDigits"] == digits, "digit metadata mismatch")
    budget = case["maxGeneratedDigits"]
    chars = case["maxOutputCharacters"]
    check(type(budget) is int and 0 <= budget <= 1000, "invalid digit budget")
    check(type(chars) is int and 1 <= chars <= 10000, "invalid character budget")
    fallback = "expansionLimit" if digits > budget else None
    candidate = (str(value.numerator) if value.denominator == 1 else
                 f"{value.numerator}/{value.denominator}") if fallback else ideal
    error = "limit" if len(candidate) > chars else None
    check(case["expectedFallback"] == fallback, "fallback metadata mismatch")
    check(case["expectedError"] == error, "output-budget metadata mismatch")
    check(case["expectedText"] == (None if error else candidate),
          "expected text mismatch")
    expected_format = None if error else ("fraction" if fallback else
                                          "exactRecurringDecimal" if b else "exactDecimal")
    check(case["expectedFormat"] == expected_format, "format metadata mismatch")


def main():
    data = json.loads(PLAN.read_text(encoding="utf-8"))
    require(data["schemaVersion"] == 1, "unsupported planning schema")
    require(data["status"] == "planned", "plan must remain planned")
    require(data["evidence"] == "ownMathematicalEvidence", "wrong evidence")
    require(data["originalDeviceVerified"] is False, "no original-device proof")
    cases = data["cases"]
    require(20 <= len(cases) <= 30, "expected 20..30 bounded planning fixtures")
    require(len({case["id"] for case in cases}) == len(cases), "duplicate IDs")
    for case in cases:
        check_case(case)
    print(f"PLAN ONLY: {len(cases)} fixtures mathematically consistent "
          "(closed-form fractions and budget metadata).")
    print("No calculator implementation, Dart/Flutter tests, or original device tested.")


if __name__ == "__main__":
    main()
