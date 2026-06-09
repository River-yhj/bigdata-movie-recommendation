# 영화 추천 및 트렌드 분석 시스템

> 빅데이터 프로그래밍 기말 프로젝트 — TMDB API + MovieLens 기반 배치 분석 파이프라인

---

## 1. 문제 정의

스트리밍 플랫폼은 방대한 양의 영화 데이터를 보유하고 있지만, **어떤 장르가 사랑받고, 흥행과 평점이 연관되는지, 시대별로 트렌드가 어떻게 변화했는지**를 파악하려면 대규모 분산 처리가 필요함.

이 프로젝트는 TMDB API와 MovieLens 데이터를 기반으로 빅데이터 파이프라인을 구축하여 아래 세 가지 분석을 합니다:

| # | 분석 | 의의 |
|---|---|---|
| Q1 | **장르별 평점 분포** — 어떤 장르가 높은 평점을 받으며, 투표 수 분포는 어떻게 다른가? | 콘텐츠 카테고리별 사용자 만족도 및 대중성 패턴 파악 |
| Q2 | **예산/수익과 평점의 상관관계** — 제작비가 많이 든 영화가 평점도 높은가? | 흥행 요소와 작품성의 관계 분석 |
| Q3 | **시대별 장르 흥망성쇠** — 1980년대부터 2024년까지 장르 인기는 어떻게 변화했는가? | 영화 소비에서 나타나는 문화적 변화 포착 |

---

## 2. 기술 스택

```
데이터 출처   : TMDB API (themoviedb.org) — 영화 메타데이터, 장르, 예산, 수익, 평점
               MovieLens Latest Dataset — 사용자 평점 (ratings.csv 891MB, 2,900만+ 건)
수집          : Python (requests, 페이지 단위 자동 수집 + 연도별 분할 저장)
저장          : HDFS (CSV -> 연도별 파티션)
전처리/분석   : Apache Pig (Latin 스크립트) — JOIN, GROUP BY, FILTER, 집계
               Apache Spark (PySpark DataFrame API) — 대용량 MovieLens × TMDB JOIN 처리
시각화        : Apache Zeppelin (내장 차트)
실행 환경     : HDP Sandbox (Hadoop 3.x, Pig 0.16.x, Spark 2.x) + PySpark 로컬
```

---

## 3. 시스템 아키텍처

```
[데이터 수집]               [저장]           [처리/분석]                  [출력]
Python 수집 스크립트  ->   HDFS (원본 CSV) -> Apache Pig (Q1/Q2/Q3)  -> 분석 결과
(TMDB API 호출,             |                 PySpark (Q1/Q3 JOIN)       |
 연도별 분할 저장)          연도별 파티션                                Zeppelin 시각화
MovieLens Dataset   ->
(ratings 891MB)
```

---

## 4. 데이터 규모

| 데이터셋 | 규모 | 비고 |
|---|---|---|
| TMDB 영화 메타데이터 | 약 78,593편 (1980~2024) | 장르, 평점, 예산, 수익 |
| MovieLens ratings.csv | 891MB | 실제 사용자 평점 |
| MovieLens × TMDB JOIN | 29,774,614건 | Q1/Q3 분석 대상 |

---

## 5. 레포지토리 구조

```
bigdata-movie-recommendation/
├── README.md
├── run_pipeline.sh                 # 전체 파이프라인 자동화 스크립트
├── data/
│   └── sample/                     # 샘플 데이터 (연도별 100행)
├── src/
│   ├── ingest/
│   │   ├── fetch_tmdb.py           # TMDB API 수집 + HDFS 업로드
│   │   ├── fetch_budget.py         # 예산/수익 데이터 수집
│   │   ├── convert_genres.py       # 장르 ID -> 장르명 변환
│   │   └── join_budget.py          # 영화 데이터 + 예산 데이터 조인
│   └── analyze/
│       ├── q1_genre_rating_v2.pig  # Q1: 장르별 평점 + 투표 수 분포 (TMDB)
│       ├── q1_movielens.pig        # Q1: 장르별 실제 사용자 평점 (MovieLens × TMDB)
│       ├── q2_budget_rating.pig    # Q2: 예산/수익과 평점 상관관계
│       ├── q3_genre_trend.pig      # Q3: 시대별 장르 트렌드 (TMDB)
│       ├── q3_movielens.pig        # Q3: 시대별 장르 트렌드 (MovieLens × TMDB)
│       └── movielens_analysis.py   # PySpark 로컬 분석 (MovieLens × TMDB 대용량 JOIN)
└── .gitignore
```

---

## 6. 데이터 출처

| 데이터셋 | 출처 | 수집 방법 | 형식 |
|---|---|---|---|
| 영화 메타데이터 | [TMDB API](https://developer.themoviedb.org/) | REST API (페이지 단위 수집) | JSON -> CSV |
| 연도별 분할 데이터 | TMDB API discover/movie 엔드포인트 | 연도 파라미터로 분할 수집 (1980-2024) | CSV |
| 예산/수익 데이터 | TMDB API /movie/{id} 엔드포인트 | 영화 ID별 상세 정보 수집 | CSV |
| 사용자 평점/링크 | [MovieLens Latest](https://grouplens.org/datasets/movielens/latest/) | 공개 데이터셋 다운로드 | CSV |

원본 데이터는 `.gitignore`로 제외하며, `data/sample/` 에 연도별 100행 샘플만 커밋합니다.

---

## 7. 실행 방법

### 사전 요건
- HDP Sandbox 실행 중 (HDFS, Pig, Spark 접근 가능)
- Python 3.x, `requests` 패키지 설치
- TMDB API 키 발급 ([tmdb.org](https://www.themoviedb.org/settings/api) 에서 무료 발급)
- API 키를 `.env` 파일에 저장 (`TMDB_API_KEY=your_key`)
- MovieLens Latest Dataset 다운로드 ([grouplens.org](https://grouplens.org/datasets/movielens/latest/))

### 전체 파이프라인 자동 실행 (HDP Sandbox)
```bash
bash run_pipeline.sh
```

### 단계별 실행

#### Step 1 — 데이터 수집 및 HDFS 업로드
```bash
export TMDB_API_KEY=your_key
python3.6 src/ingest/fetch_tmdb.py
python3.6 src/ingest/convert_genres.py
python3.6 src/ingest/fetch_budget.py
python3.6 src/ingest/join_budget.py
```

#### Step 2 — Pig 분석 (HDP Sandbox)
```bash
pig -f src/analyze/q1_genre_rating_v2.pig
pig -f src/analyze/q2_budget_rating.pig
pig -f src/analyze/q3_genre_trend.pig
```

#### Step 3 — PySpark 대용량 분석 (로컬, MovieLens × TMDB JOIN)
```bash
# 사전 요건: pyspark 설치 (uv pip install pyspark), Java 11+
python src/analyze/movielens_analysis.py
```
결과는 `data/spark_output/` 에 저장됩니다.

#### Step 4 — 시각화
Apache Zeppelin (localhost:9995) 에서 결과 확인

### 샘플 데이터로 빠른 실행

#### 1. 샘플 데이터 HDFS 업로드
```bash
hdfs dfs -mkdir -p /user/maria_dev/movies/joined
hdfs dfs -put data/sample/*.csv /user/maria_dev/movies/joined/
```

#### 2. Pig 분석 실행
```bash
pig -f src/analyze/q1_genre_rating_v2.pig
pig -f src/analyze/q2_budget_rating.pig
pig -f src/analyze/q3_genre_trend.pig
```

---

## 8. AI 도구 사용 내역

- Claude (Anthropic): Pig 스크립트 디버깅, Zeppelin/PySpark 코드 디버깅, 보고서 구조 다듬기 및 표 작성 보조
