"""Check planned test catalog structure, not calculator behavior. Standard library only."""
from pathlib import Path
import csv
import json
import re

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / 'tests' / 'reference'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_catalog(name, columns, id_column):
    path = REFERENCE / name
    with path.open(encoding='utf-8-sig', newline='') as handle:
        reader = csv.DictReader(handle)
        require(set(columns) <= set(reader.fieldnames or []), f'{name}: missing columns')
        rows = list(reader)
    require(rows, f'{name}: empty catalog')
    ids = [row[id_column] for row in rows]
    require(len(set(ids)) == len(ids), f'{name}: duplicate IDs')
    require(all(ids), f'{name}: blank ID')
    require(all(row.get('status') == 'planned' for row in rows),
            f'{name}: this checker accepts planning records only; execution needs a separate report')
    return rows, set(ids)


def main():
    keys, key_ids = read_catalog('key_coverage.csv',
        ['key_id', 'label', 'primary', 'shift', 'alpha', 'mode_overrides',
         'contexts_to_test', 'test_families', 'status'], 'key_id')
    expected_keys = {f'KEY_{n}' for n in range(10)} | {
        'KEY_SHIFT', 'KEY_ALPHA', 'KEY_MENU', 'KEY_ON',
        'KEY_LEFT', 'KEY_UP', 'KEY_DOWN', 'KEY_RIGHT',
        'KEY_OPTN', 'KEY_CALC', 'KEY_INTEGRAL', 'KEY_X',
        'KEY_FRACTION', 'KEY_SQRT', 'KEY_SQUARE', 'KEY_POWER',
        'KEY_LOG_BASE', 'KEY_LN', 'KEY_NEGATE', 'KEY_DMS',
        'KEY_RECIPROCAL', 'KEY_SIN', 'KEY_COS', 'KEY_TAN',
        'KEY_STO', 'KEY_ENG', 'KEY_LPAREN', 'KEY_RPAREN',
        'KEY_SD', 'KEY_M_PLUS', 'KEY_DEL', 'KEY_AC',
        'KEY_MULTIPLY', 'KEY_DIVIDE', 'KEY_ADD', 'KEY_SUBTRACT',
        'KEY_DECIMAL', 'KEY_EXP10', 'KEY_ANS', 'KEY_EQUALS'
    }
    require(key_ids == expected_keys,
            f'Key inventory mismatch: missing={expected_keys-key_ids}, extra={key_ids-expected_keys}')
    for row in keys:
        require(all(value is not None and value.strip() for value in row.values()),
                f"Incomplete key plan: {row['key_id']}")
    functions, _ = read_catalog('function_coverage.csv',
        ['function_id', 'group', 'function', 'normal_case', 'boundary_case',
         'invalid_case', 'independent_oracle', 'source', 'existing_cases', 'status'], 'function_id')
    for row in functions:
        require(all(row.get(field, '').strip() for field in
            ['group', 'function', 'normal_case', 'boundary_case', 'invalid_case',
             'independent_oracle', 'source']), f"Incomplete function plan: {row['function_id']}")

    reference_text = (ROOT / 'docs' / 'REFERENZTESTS.md').read_text(encoding='utf-8-sig')
    reference_ids = set(re.findall(r'^\| ([KEG]\d+) \|', reference_text, re.MULTILINE))
    for row in functions:
        links = set(re.findall(r'\b[KEG]\d+\b', row.get('existing_cases', '')))
        require(links <= reference_ids,
                f"{row['function_id']}: unknown reference IDs {links-reference_ids}")
    case_ids = set()
    count = 0
    for path in sorted((REFERENCE / 'scenarios').glob('*.json')):
        data = json.loads(path.read_text(encoding='utf-8-sig'))
        require(data.get('format_version') == 1, f'{path.name}: unsupported format')
        for case in data['cases']:
            case_id = case['id']
            require(case_id not in case_ids, f'Duplicate scenario ID: {case_id}')
            case_ids.add(case_id)
            require(case.get('status') == 'planned', f'{case_id}: not a planning record')
            require(case.get('initial') and case.get('expected') and case.get('oracle'),
                    f'{case_id}: missing starting state, expectation or oracle')
            require(case['oracle'].get('kind') and case['oracle'].get('document'),
                    f'{case_id}: incomplete provenance')
            if 'reference_case_id' in case:
                require(case['reference_case_id'] in reference_ids, f'{case_id}: unknown reference ID')
            if case['kind'] == 'keys':
                require(case.get('steps'), f'{case_id}: empty sequence')
                for step in case['steps']:
                    require(step.get('press') in key_ids, f'{case_id}: unknown key')
            elif case['kind'] == 'math':
                require(case.get('input', {}).get('expression'), f'{case_id}: missing math input')
            else:
                raise ValueError(f'{case_id}: unsupported case kind')
            count += 1
    require(count > 0, 'No example scenarios found')
    print(f'Katalogstruktur geprueft: {len(keys)} Tasten, {len(functions)} Funktionspositionen, '
          f'{count} Beispielablaeufe, {len(reference_ids)} Handbuchfall-IDs.')
    print('Nur Planungsdaten geprueft. Keine Rechnung, UI oder Originalsoftware ausgefuehrt.')


if __name__ == '__main__':
    main()
