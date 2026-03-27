# PKGF Intelligence Emergence - Part 2
## N体エージェントによる社会的知性と階層構造の創発シミュレーション

Part2では、Part1の理論（12次元多様体、16要素、PKGF流動）を継承しつつ、個体数を $N$ 体に拡張することで、集団的なダイナミクスを検証します。

### 1. 研究の焦点
- **集団的秩序**: 相互斥力と共通目標のバランスによる、空間的な自己組織化。
- **社会的階層**: 複数のエージェント間での「リーダー・フォロワー」関係の多段階化。
- **権力勾配**: リソース分配の偏りが、幾何学的な安定アトラクタとしてどのように固定化されるか。

### 2. 実行方法

#### Python
```bash
python3 Part2/emergence_sim.py
```

#### Fortran
```bash
gfortran -O3 -o Part2/emergence_sim_nbody Part2/emergence_sim.f90
./Part2/emergence_sim_nbody
```

### 3. フェーズ定義
- **Phase D: Group Stability**: $N$ 体の物理的均衡と配置パターンの観測。
- **Phase E: Social Hierarchy**: 飢餓と緊張に基づく、役割分担の多段階創発の検証。

### 4. ディレクトリ構造
- `Part2/emergence_sim.py`: N体対応Pythonシミュレータ
- `Part2/emergence_sim.f90`: N体対応Fortranシミュレータ
- `Part2/EXPERIMENT_PLAN.md`: 詳細な実験計画と創発指標
- `Part2/logs/`: 実行結果の保存先
