# 영화 추천 및 트렌드 분석 시스템

> 빅데이터 프로그래밍 기말 프로젝트 — TMDB API 기반 배치 분석 파이프라인

---

## 1. 문제 정의

스트리밍 플랫폼은 방대한 양의 영화 데이터를 보유하고 있지만, **어떤 장르가 사랑받고, 흥행과 평점이 연관되는지, 시대별로 트렌드가 어떻게 변화했는지**를 파악하려면 대규모 분산 처리가 필요함.

이 프로젝트는 TMDB API를 통해 수집한 영화 데이터를 기반으로 빅데이터 파이프라인을 구축하여 아래 세 가지 분석을 합니다:

| # | 분석 | 의의 |
|---|---|---|
| Q1 | **장르별 평점 분포** — 어떤 장르가 높은 평점을 받으며, 투표 수 분포는 어떻게 다른가? | 콘텐츠 카테고리별 사용자 만족도 및 대중성 패턴 파악 |
| Q2 | **예산/수익과 평점의 상관관계** — 제작비가 많이 든 영화가 평점도 높은가? | 흥행 요소와 작품성의 관계 분석 |
| Q3 | **시대별 장르 흥망성쇠** — 2015년부터 2024년까지 장르 인기는 어떻게 변화했는가? | 영화 소비에서 나타나는 문화적 변화 포착 |

---

## 2. 기술 스택

```
데이터 출처   : TMDB API (themoviedb.org) — 영화 메타데이터, 장르, 예산, 수익, 평점
수집          : Python (requests, 페이지 단위 자동 수집 + 연도별 분할 저장)
저장          : HDFS (CSV -> 연도별 파티션)
전처리/분석   : Apache Pig (Latin 스크립트) — JOIN, GROUP BY, FILTER, 집계
                Apache Spark (DataFrame API) — 대용량 전처리 및 분석
시각화        : Apache Zeppelin (내장 차트)
실행 환경     : HDP Sandbox (Hadoop 3.x, Pig 0.16.x, Spark 2.x)
```

---

## 3. 시스템 아키텍처

```
[데이터 수집]               [저장]           [처리/분석]                  [출력]
Python 수집 스크립트  ->   HDFS (원본 CSV) -> Apache Pig              -> Q1/Q2/Q3 결과
(TMDB API 호출,             |                 Apache Spark (DataFrame)    |
 연도별 분할 저장)          연도별 파티션                                Zeppelin 시각화
```

---

## 4. 레포지토리 구조

```
bigdata-movie-recommendation/
├── README.md
├── run_pipeline.sh                 # 전체 파이프라인 자동화 스크립트
├── data/
│   └── README.md                   # 데이터 출처, 스키마, 다운로드 방법
├── src/
│   ├── ingest/
│   │   ├── fetch_tmdb.py           # TMDB API 수집 + HDFS 업로드
│   │   ├── fetch_budget.py         # 예산/수익 데이터 수집
│   │   ├── convert_genres.py       # 장르 ID -> 장르명 변환
│   │   └── join_budget.py          # 영화 데이터 + 예산 데이터 조인
│   └── analyze/
│       ├── q1_genre_rating.pig     # Q1: 장르별 평점 분포
│       ├── q1_genre_rating_v2.pig  # Q1 v2: 장르별 평점 + 투표 수 분포
│       ├── q2_budget_rating.pig    # Q2: 예산/수익과 평점 상관관계
│       └── q3_genre_trend.pig      # Q3: 시대별 장르 트렌드
└── .gitignore
```

---

## 5. 데이터 출처

| 데이터셋 | 출처 | 수집 방법 | 형식 |
|---|---|---|---|
| 영화 메타데이터 | [TMDB API](https://developer.themoviedb.org/) | REST API (페이지 단위 수집) | JSON -> CSV |
| 연도별 분할 데이터 | TMDB API discover/movie 엔드포인트 | 연도 파라미터로 분할 수집 (2015-2024) | CSV |
| 예산/수익 데이터 | TMDB API /movie/{id} 엔드포인트 | 영화 ID별 상세 정보 수집 | CSV |

원본 데이터는 `.gitignore`로 제외하며, `data/sample/` 에 500행 샘플만 커밋합니다.

---

## 6. 실행 방법

### 사전 요건
- HDP Sandbox 실행 중 (HDFS, Pig, Spark 접근 가능)
- Python 3.x, `requests` 패키지 설치
- TMDB API 키 발급 ([tmdb.org](https://www.themoviedb.org/settings/api) 에서 무료 발급)
- API 키를 `.env` 파일에 저장 (`TMDB_API_KEY=your_key`)

### 전체 파이프라인 자동 실행
```bash
bash run_pipeline.sh
```

### 단계별 실행

#### Step 1 — 데이터 수집 및 HDFS 업로드
```bash
source .env
python3.6 src/ingest/fetch_tmdb.py
python3.6 src/ingest/convert_genres.py
python3.6 src/ingest/fetch_budget.py
python3.6 src/ingest/join_budget.py
```

#### Step 2 — 분석 쿼리 실행
```bash
pig -f src/analyze/q1_genre_rating_v2.pig
pig -f src/analyze/q2_budget_rating.pig
pig -f src/analyze/q3_genre_trend.pig
```

#### Step 3 — 시각화
Apache Zeppelin (localhost:9995) 에서 결과 확인

---

## 7. AI 도구 사용 내역

- Claude: README 구조 제안, Pig 스크립트 디버깅
