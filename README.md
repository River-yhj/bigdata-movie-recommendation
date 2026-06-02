# 영화 추천 및 트렌드 분석 시스템

> 빅데이터 프로그래밍 기말 프로젝트 — TMDB API 기반 배치 분석 파이프라인

---

## 1. 문제 정의

스트리밍 플랫폼은 방대한 양의 영화 데이터를 보유하고 있지만, **어떤 장르가 사랑받고, 흥행과 평점이 연관되는지, 시대별로 트렌드가 어떻게 변화했는지**를 파악하려면 대규모 분산 처리가 필요함.

이 프로젝트는 TMDB API를 통해 수집한 영화 데이터를 기반으로 빅데이터 파이프라인을 구축하여 아래 세 가지 분석을 합니다:

| # | 분석 | 의의 |
|---|---|---|
| Q1 | **장르별 평점 분포** — 어떤 장르가 높은 평점을 받으며, 분포는 어떻게 다른가? | 콘텐츠 카테고리별 사용자 만족도 패턴 파악 |
| Q2 | **예산/수익과 평점의 상관관계** — 제작비가 많이 든 영화가 평점도 높은가? | 흥행 요소와 작품성의 관계 분석 |
| Q3 | **시대별 장르 흥망성쇠** — 1980년대부터 2020년대까지 장르 인기는 어떻게 변화했는가? | 영화 소비에서 나타나는 문화적 변화 포착 |

---

## 2. 기술 스택

```
데이터 출처   : TMDB API (themoviedb.org) — 영화 메타데이터, 장르, 예산, 수익, 평점
수집          : Python (requests, 페이지 단위 자동 수집 + 연도별 분할 저장)
저장          : HDFS (CSV -> 연도별 파티션)
전처리/분석   : Apache Pig (Latin 스크립트) — JOIN, GROUP BY, FILTER, 집계
                Apache Spark (DataFrame API) — 대용량 전처리 및 분석
시각화        : Matplotlib / Seaborn (결과 노트북)
실행 환경     : HDP Sandbox (Hadoop 3.x, Pig 0.17.x, Spark 2.x)
```

**추후 확장 예정 (수업 진도에 맞춰 단계적 도입)**

| 도구 | 역할 | 도입 시기 |
|---|---|---|
| Apache Sqoop | RDBMS -> HDFS 데이터 적재 | 도입 완료 |
| Apache Flume | 로그 데이터 수집 파이프라인 | 도입 완료 |
| Apache Spark | 대용량 전처리 및 DataFrame 분석 | 도입 완료 |
| Apache Hive | HiveQL 기반 집계 쿼리 | 14주차 |
| ~~Spark MLlib~~ | ~~ALS 협업 필터링 추천 모델~~ |~~14주차~~|

---

spark MLlib은 데이터가 없어서 **불가능**


## 3. 시스템 아키텍처

```
[데이터 수집]               [저장]           [처리/분석]                  [출력]
Python 수집 스크립트  ->   HDFS (원본 CSV) -> Apache Pig              -> Q1/Q2/Q3 결과
(TMDB API 호출,             |                 Apache Spark (DataFrame)    |
 연도별 분할 저장)          연도별 파티션                                Matplotlib 시각화
```

---

## 4. 레포지토리 구조

```
bigdata-movie-recommendation/
├── README.md
├── data/
│   └── README.md                   # 데이터 출처, 스키마, 다운로드 방법
├── src/
│   ├── ingest/
│   │   └── fetch_tmdb.py           # TMDB API 수집 + HDFS 업로드
│   ├── pipeline/
│   │   ├── preprocess.pig          # 전처리 Pig 스크립트
│   │   └── preprocess_spark.py     # 전처리 Spark 스크립트
│   └── analyze/
│       ├── q1_genre_rating.pig     # Q1: 장르별 평점 분포
│       ├── q2_budget_rating.pig    # Q2: 예산/수익과 평점 상관관계
│       ├── q3_genre_trend.pig      # Q3: 시대별 장르 트렌드
│       └── visualize.ipynb         # 결과 시각화 노트북
└── .gitignore
```

---

## 5. 데이터 출처

| 데이터셋 | 출처 | 수집 방법 | 형식 |
|---|---|---|---|
| 영화 메타데이터 | [TMDB API](https://developer.themoviedb.org/) | REST API (페이지 단위 수집) | JSON -> CSV |
| 연도별 분할 데이터 | TMDB API discover/movie 엔드포인트 | 연도 파라미터로 분할 수집 (2015-2024) | CSV |

원본 데이터는 `.gitignore`로 제외하며, `data/sample/` 에 500행 샘플만 커밋합니다.

**수집 방법:** `src/ingest/fetch_tmdb.py`가 TMDB API를 페이지 단위로 호출하여 연도별 CSV로 저장 후 HDFS에 업로드합니다. 재실행 가능하도록 설계되어 있습니다.

---

## 6. 실행 방법

### 사전 요건
- HDP Sandbox 실행 중 (HDFS, Pig, Spark 접근 가능)
- Python 3.x, `requests` 패키지 설치
- TMDB API 키 발급 ([tmdb.org](https://www.themoviedb.org/settings/api) 에서 무료 발급)

### Step 1 — 데이터 수집 및 HDFS 업로드
```bash
export TMDB_API_KEY=your_api_key_here
python3 src/ingest/fetch_tmdb.py
```

### Step 2 — 전처리 (Pig)
```bash
pig -f src/pipeline/preprocess.pig
```

### Step 3 — 전처리 (Spark)
```bash
spark-submit src/pipeline/preprocess_spark.py
```

### Step 4 — 분석 쿼리 실행
```bash
pig -f src/analyze/q1_genre_rating.pig
pig -f src/analyze/q2_budget_rating.pig
pig -f src/analyze/q3_genre_trend.pig
```

### Step 5 — 시각화
`src/analyze/visualize.ipynb`를 Jupyter에서 열어 실행합니다.
혹은 zeppelin 사용

---

## 7. AI 도구 사용 내역

- Claude: README 구조 제안, Pig 스크립트 디버깅
