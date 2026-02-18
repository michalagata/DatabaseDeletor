# Comprehensive Open Data Sources for Expert-Level AI/LLM Training

> **Purpose:** Reference catalog of publicly available datasets suitable for training neural networks and LLM models for an expert-level database management/deletion system with AI capabilities.
>
> **Last Updated:** 2026-02-18

---

## Table of Contents

1. [Polish-Language Data Sources](#1-polish-language-data-sources)
2. [Global/English Pre-Training Corpora](#2-globalenglish-pre-training-corpora)
3. [Specialized Technical / Database Data Sources](#3-specialized-technical--database-data-sources)
4. [Code Datasets](#4-code-datasets)
5. [Multi-Domain Knowledge Bases](#5-multi-domain-knowledge-bases)
6. [Feedback / RLHF / Preference Datasets](#6-feedback--rlhf--preference-datasets)
7. [Instruction-Tuning Datasets](#7-instruction-tuning-datasets)
8. [Summary Matrix](#8-summary-matrix)

---

## 1. Polish-Language Data Sources

### 1.1 PLLuM Training Corpus

- **Name:** PLLuM (Polish Large Language Model) Pre-Training Corpus
- **URL:** https://huggingface.co/CYFRAGOVPL | https://arxiv.org/abs/2511.03823
- **License:** Two tiers: fully open models use ~30B tokens (open license); full ~150B token corpus uses CC-BY-NC-4.0 due to copyright
- **Size:** ~140 billion tokens (Polish text)
- **Domains:** Literature, academic texts, news media, legal documents, online content, public administration, dialogic materials (8M tokens)
- **How to fetch:** HuggingFace Hub via CYFRAGOVPL organization; models available on HuggingFace and Ollama
- **Good for:** The single most comprehensive Polish-language pre-training corpus available. Covers legal, academic, administrative, and conversational Polish. Essential for any Polish-language LLM.

### 1.2 SpeakLeash / Bielik Dataset

- **Name:** SpeakLeash (Spichlerz) Polish Text Database
- **URL:** https://huggingface.co/speakleash
- **License:** Open-source (project-specific; check individual dataset cards)
- **Size:** Largest documented Polish text collection; 294 million documents selected for Bielik v3 training
- **Domains:** Web text, curated Polish documents, CommonCrawl Polish subset
- **How to fetch:** HuggingFace Hub under `speakleash` organization
- **Good for:** Polish-language pre-training and fine-tuning. Used to train the Bielik family of Polish LLMs (1.5B to 11B parameters). High quality, well-documented, community-curated.

### 1.3 National Corpus of Polish (NKJP)

- **Name:** Narodowy Korpus Jezyka Polskiego (NKJP)
- **URL:** https://nkjp.pl/ | https://huggingface.co/datasets/ipipan/nkjp1m
- **License:** 1M-word subcorpus: CC-BY; Full corpus: GNU GPL v3 (limited access; may require direct contact)
- **Size:** Full corpus: ~1.5 billion words; Balanced subcorpus: 300M words; Manually annotated: 1M words
- **Domains:** Classic literature, daily newspapers, specialist periodicals, transcripts of conversations, internet texts
- **How to fetch:** 1M subcorpus downloadable from nkjp.pl and HuggingFace (`ipipan/nkjp1m`); full corpus requires institutional access
- **Good for:** Polish morphosyntactic training, lemmatization, POS tagging, linguistic analysis. The gold standard for Polish NLP annotation.

### 1.4 OSCAR Polish Subset

- **Name:** OSCAR (Open Super-large Crawled ALMAnaCH coRpus) - Polish
- **URL:** https://huggingface.co/oscar-corpus
- **License:** CC0 for metadata; individual text licenses vary (derived from Common Crawl)
- **Size:** ~49-109 GB of Polish text (varies by version/deduplication)
- **Domains:** Web crawl data in Polish
- **How to fetch:** HuggingFace Datasets (`oscar-corpus/oscar`); filter by language `pl`
- **Good for:** Large-scale Polish web text for pre-training. Good complement to curated corpora.

### 1.5 CulturaX Polish Subset

- **Name:** CulturaX - Polish language subset
- **URL:** https://huggingface.co/datasets/uonlp/CulturaX
- **License:** Varies by source (mC4 + OSCAR combined); check dataset card
- **Size:** Part of 6.3 trillion tokens across 167 languages; Polish subset is substantial
- **Domains:** Web text, cleaned and deduplicated
- **How to fetch:** HuggingFace Datasets (`uonlp/CulturaX`); filter by language `pl`
- **Good for:** High-quality multilingual pre-training. Merges mC4 and OSCAR with rigorous cleaning pipeline (language ID, URL filtering, metric-based cleaning, deduplication).

### 1.6 Polish Wikipedia Dump

- **Name:** Wikipedia (pl) Database Dump
- **URL:** https://dumps.wikimedia.org/plwiki/ | https://huggingface.co/datasets/wikimedia/wikipedia
- **License:** CC-BY-SA 3.0
- **Size:** ~3-4 GB compressed (articles only)
- **Domains:** Encyclopedic knowledge in Polish
- **How to fetch:** Direct download from dumps.wikimedia.org; or HuggingFace Datasets (`wikimedia/wikipedia`, config `20231101.pl`)
- **Good for:** Polish factual knowledge, encyclopedic coverage, structured knowledge extraction.

### 1.7 KLEJ Benchmark Datasets

- **Name:** KLEJ (Kompleksowa Lista Ewaluacji Jezykowych)
- **URL:** https://klejbenchmark.com/ | https://huggingface.co/allegro
- **License:** Various (check individual dataset cards on HuggingFace)
- **Size:** 9 evaluation tasks; varies per task
- **Datasets included:** PolEmo 2.0 (sentiment, 8000+ reviews), Allegro Reviews, CDSC (textual entailment), and others
- **How to fetch:** HuggingFace Datasets under `allegro/` organization (e.g., `allegro/klej-polemo2-in`)
- **Good for:** Evaluation and fine-tuning for Polish language understanding tasks. Not for pre-training but essential for benchmarking Polish model quality.

### 1.8 LEPISZCZE Benchmark

- **Name:** LEPISZCZE - Comprehensive NLP Benchmark for Polish
- **URL:** https://github.com/CLARIN-PL/LEPISZCZE
- **License:** Check repository
- **Size:** Multiple task datasets
- **How to fetch:** GitHub repository
- **Good for:** Extended Polish NLP evaluation beyond KLEJ; includes more diverse task types.

---

## 2. Global/English Pre-Training Corpora

### 2.1 Common Crawl

- **Name:** Common Crawl
- **URL:** https://commoncrawl.org/ | https://data.commoncrawl.org/
- **License:** No restrictions on use; terms of use apply
- **Size:** ~250 TB per monthly crawl; petabytes total (since 2008); ~2 billion web pages per crawl
- **Domains:** Entire open web
- **How to fetch:** Free access via AWS S3 (Open Data Sponsorship Program); no AWS account required for HTTP access; also available via direct download
- **Good for:** The foundational raw web dataset. Virtually every major pre-training corpus (FineWeb, RedPajama, OSCAR, CulturaX) is derived from Common Crawl. Use processed versions unless you need custom filtering.

### 2.2 FineWeb (HuggingFace)

- **Name:** FineWeb / FineWeb-Edu / FineWeb-2
- **URL:** https://huggingface.co/datasets/HuggingFaceFW/fineweb | https://huggingface.co/datasets/HuggingFaceFW/fineweb-2
- **License:** ODC-BY 1.0
- **Size:** FineWeb: ~15 trillion tokens (~20 TB), 5 billion documents; FineWeb-2: multilingual, ~20 TB
- **Domains:** Cleaned web text from 96 Common Crawl snapshots (2013-2024+)
- **How to fetch:** HuggingFace Datasets; downloadable by individual CC snapshot or full dataset; v1.4.0 (2025) adds 2025 snapshots
- **Good for:** Currently the largest and highest-quality publicly available clean English pre-training dataset. FineWeb-Edu is filtered for educational content. FineWeb-2 covers multiple languages. State of the art for pre-training.

### 2.3 RedPajama-Data-V2

- **Name:** RedPajama-Data-V2
- **URL:** https://huggingface.co/datasets/togethercomputer/RedPajama-Data-V2 | https://github.com/togethercomputer/RedPajama-Data
- **License:** Apache 2.0 (for the code/pipeline); data is Common Crawl derived
- **Size:** 100+ billion documents from 84 CC snapshots; 30B documents with quality signals; 20B deduplicated
- **Domains:** Web text in English, French, Spanish, German, Italian
- **How to fetch:** HuggingFace Datasets; processing scripts on GitHub
- **Good for:** Massive multilingual pre-training with built-in quality signals and deduplication metadata. Well-documented pipeline.

### 2.4 RedPajama-Data-1T

- **Name:** RedPajama-Data-1T (v1)
- **URL:** https://huggingface.co/datasets/togethercomputer/RedPajama-Data-1T
- **License:** Apache 2.0 (pipeline); mixed (data sources)
- **Size:** ~1.2 trillion tokens
- **Components:** CommonCrawl, C4, GitHub, Books, ArXiv, Wikipedia, StackExchange
- **How to fetch:** HuggingFace Datasets
- **Good for:** A curated LLaMA-recipe replication dataset. Good balance of web, code, academic, and reference text.

### 2.5 The Pile (EleutherAI)

- **Name:** The Pile
- **URL:** https://pile.eleuther.ai/ | https://huggingface.co/datasets/EleutherAI/pile
- **License:** Mixed (22 subsets, each with own license); MIT for the code
- **Size:** ~825 GiB (886 GB), 22 diverse subsets
- **Components:** Pile-CC, PubMed Central, Books3, OpenWebText2, ArXiv, GitHub, FreeLaw, Stack Exchange, USPTO Backgrounds, PubMed Abstracts, Gutenberg, OpenSubtitles, Wikipedia, DM Mathematics, Ubuntu IRC, BookCorpus2, EuroParl, HackerNews, YouTube Subtitles, PhilPapers, NIH ExPorter, Enron Emails
- **How to fetch:** HuggingFace Datasets; also via The Eye (torrent)
- **Good for:** The pioneering diverse pre-training dataset. Excellent for breadth: academic papers, legal text, code, books, conversations. Very well-studied.

### 2.6 Common Pile v0.1 (EleutherAI, 2025)

- **Name:** Common Pile v0.1
- **URL:** https://blog.eleuther.ai/common-pile/
- **License:** All data is explicitly licensed for AI training use
- **Size:** ~8 TB
- **Domains:** Web text, books, academic papers -- only works with clear licensing permissions
- **How to fetch:** HuggingFace (check EleutherAI blog for links)
- **Good for:** The legally safest large pre-training dataset. Released June 2025 in partnership with Hugging Face, Poolside, and the US Library of Congress. If legal compliance matters, this is the dataset to use.

### 2.7 Dolma (Allen AI)

- **Name:** Dolma
- **URL:** https://huggingface.co/datasets/allenai/dolma | https://allenai.github.io/dolma/
- **License:** ODC-BY
- **Size:** Dolma 1.7: 2.3 trillion tokens; Dolma 3 Mix: ~6 trillion tokens
- **Components:** Web content (CC), academic publications (Semantic Scholar), code, books, encyclopedic materials
- **How to fetch:** HuggingFace Hub (`allenai/dolma`); also `allenai/dolma3_mix-6T-1025`; Python toolkit via `pip install dolma`
- **Good for:** Very high-quality, well-documented pre-training corpus. Used to train OLMo models. Dolma 3 is one of the largest openly available curated pre-training mixes. Excellent tooling for custom filtering.

### 2.8 SlimPajama (Cerebras)

- **Name:** SlimPajama-627B
- **URL:** https://huggingface.co/datasets/cerebras/SlimPajama-627B
- **License:** Apache 2.0
- **Size:** 627 billion tokens (deduplicated from RedPajama-1T's 1.2T tokens)
- **Domains:** Same sources as RedPajama-1T, extensively deduplicated
- **How to fetch:** HuggingFace Datasets
- **Good for:** Cleaner, deduplicated version of RedPajama-1T. Demonstrates that aggressive deduplication improves training efficiency without quality loss.

### 2.9 Wikipedia (All Languages)

- **Name:** Wikipedia Database Dumps
- **URL:** https://dumps.wikimedia.org/ | https://huggingface.co/datasets/wikimedia/wikipedia
- **License:** CC-BY-SA 3.0
- **Size:** English: ~22 GB uncompressed (articles); all languages: varies; Wikidata: ~1.6 TB uncompressed
- **Domains:** Encyclopedic knowledge, all topics
- **How to fetch:** Direct download from dumps.wikimedia.org (monthly dumps); HuggingFace Datasets (`wikimedia/wikipedia`); date-versioned configs
- **Good for:** High-quality factual text in 300+ languages. Essential component of virtually every pre-training mix. Well-structured, regularly updated.

### 2.10 Stack Exchange Data Dump

- **Name:** Stack Exchange Data Dump
- **URL:** https://archive.org/details/stackexchange | Academic Torrents
- **License:** CC-BY-SA 4.0
- **Size:** ~92-98 GB compressed (2025 dump)
- **Domains:** Q&A across 170+ sites: Stack Overflow, Server Fault, DBA, Super User, Math, Physics, etc.
- **How to fetch:** Internet Archive (direct download); Academic Torrents (torrent); XML format (7z/bzip2 compressed)
- **Good for:** Expert Q&A training data. Stack Overflow is critical for code/technical knowledge. DBA Stack Exchange is directly relevant to database expertise. Very high signal-to-noise ratio due to voting/curation.

---

## 3. Specialized Technical / Database Data Sources

### 3.1 Spider Dataset (Text-to-SQL)

- **Name:** Spider: Yale Semantic Parsing and Text-to-SQL Challenge
- **URL:** https://yale-lily.github.io/spider
- **License:** CC-BY-SA 4.0
- **Size:** 10,181 questions, 5,693 unique complex SQL queries, 200 databases, 138 domains
- **Domains:** Cross-domain text-to-SQL with complex queries (JOINs, nested queries, GROUP BY, ORDER BY)
- **How to fetch:** Direct download from yale-lily.github.io/spider
- **Good for:** Training text-to-SQL capabilities. The most widely used benchmark for cross-domain SQL generation. Essential for a database management AI.

### 3.2 Spider 2.0

- **Name:** Spider 2.0 (Enterprise Text-to-SQL)
- **URL:** https://spider2-sql.github.io/ (XLang AI)
- **License:** Check project page
- **Size:** 600 complex text-to-SQL workflow problems
- **Domains:** Enterprise-level database workflows, real-world scenarios
- **How to fetch:** Project website
- **Good for:** Advanced, enterprise-grade text-to-SQL training. More realistic than Spider 1.0 for production database scenarios.

### 3.3 WikiSQL

- **Name:** WikiSQL
- **URL:** https://github.com/salesforce/WikiSQL
- **License:** BSD 3-Clause
- **Size:** 80,654 hand-annotated examples of questions and SQL queries across 24,241 tables from Wikipedia
- **Domains:** Simple SQL (SELECT/FROM/WHERE only)
- **How to fetch:** GitHub repository download
- **Good for:** Foundational text-to-SQL training. Simple queries only, but very large. Good for bootstrapping SQL understanding before fine-tuning on more complex datasets.

### 3.4 BIRD Benchmark

- **Name:** BIRD (BIg Bench for LaRge-scale Database Grounded Text-to-SQL Evaluation)
- **URL:** https://bird-bench.github.io/
- **License:** Check project page
- **Size:** 12,751 question-SQL pairs across 95 large databases (33.4 GB total database size)
- **Domains:** Real-world "dirty" data from actual databases
- **How to fetch:** Project website
- **Good for:** Most realistic text-to-SQL benchmark. Tests handling of messy real-world data, not just clean schemas. Includes Valid Efficiency Score (VES) for query optimization awareness.

### 3.5 SchemaPile

- **Name:** SchemaPile - A Large Collection of Relational Database Schemas
- **URL:** https://ir.cwi.nl/pub/34763/34763.pdf (paper); check HuggingFace/GitHub for data
- **License:** Check paper/repository
- **Size:** 221,171 database schemas; 1.7 million tables; 10 million column definitions; 700K foreign key relationships; 7 million integrity constraints; data content for 340K+ tables
- **Domains:** SQL schemas extracted from GitHub repositories
- **How to fetch:** Check paper references for download links
- **Good for:** Directly relevant to database management AI. Training schema understanding, relationship detection, constraint analysis. Unique dataset for database structure comprehension.

### 3.6 PostgreSQL / MySQL / SQL Server Documentation

- **Name:** Official Database Documentation (plain text / HTML)
- **URLs:**
  - PostgreSQL: https://www.postgresql.org/docs/ (also available as SGML/HTML dump)
  - MySQL: https://dev.mysql.com/doc/ (HTML downloadable)
  - SQL Server: https://learn.microsoft.com/en-us/sql/ (GitHub: https://github.com/MicrosoftDocs/sql-docs)
  - SQLite: https://www.sqlite.org/docs.html
  - Oracle: https://docs.oracle.com/en/database/
- **License:** PostgreSQL License (permissive); MySQL docs: GPL; SQL Server docs: CC-BY 4.0 (GitHub); SQLite: public domain
- **Size:** Hundreds of MB per vendor (HTML/text)
- **How to fetch:** Direct HTML scrape; PostgreSQL provides tar/zip of docs; Microsoft SQL docs on GitHub (`MicrosoftDocs/sql-docs`)
- **Good for:** Expert-level database administration knowledge. SQL syntax, performance tuning, configuration, security, backup/recovery. Critical for a database management tool.

### 3.7 DBA Stack Exchange

- **Name:** DBA Stack Exchange (Database Administrators)
- **URL:** Part of Stack Exchange Data Dump; site: https://dba.stackexchange.com/
- **License:** CC-BY-SA 4.0
- **Size:** ~1.5 GB compressed (part of full SE dump)
- **Domains:** Database administration Q&A: performance tuning, schema design, migration, backup, security, query optimization
- **How to fetch:** Included in Stack Exchange Data Dump (filter for `dba.stackexchange.com`)
- **Good for:** Directly relevant expert knowledge for database management. Real-world problems and solutions from professional DBAs.

### 3.8 NL2SQL Handbook / Datasets Collection

- **Name:** NL2SQL Handbook - Text-to-SQL Resources
- **URL:** https://github.com/HKUSTDial/NL2SQL_Handbook
- **License:** Various (aggregator)
- **Size:** Catalog of all major text-to-SQL datasets and techniques
- **How to fetch:** GitHub repository with links to all datasets
- **Good for:** Comprehensive index of text-to-SQL resources. Use as a starting point to identify additional specialized datasets.

---

## 4. Code Datasets

### 4.1 The Stack v2 (BigCode)

- **Name:** The Stack v2
- **URL:** https://huggingface.co/datasets/bigcode/the-stack-v2
- **License:** Mixed (per-file license detection; permissive licenses filtered)
- **Size:** 67.5 TB of code in 600+ programming languages
- **Domains:** Source code from GitHub (with license filtering and PII removal)
- **How to fetch:** HuggingFace Datasets (`bigcode/the-stack-v2`)
- **Good for:** The largest open code dataset. Used to train StarCoder2. Essential for code generation and understanding capabilities.

### 4.2 The Stack v1.2

- **Name:** The Stack v1.2
- **URL:** https://huggingface.co/datasets/bigcode/the-stack
- **License:** Mixed permissive licenses; opt-out mechanism for repository owners
- **Size:** 6.4 TB of permissively licensed source code in 384 programming languages + 54 GB GitHub issues + repo metadata
- **Domains:** Source code, issues, documentation
- **How to fetch:** HuggingFace Datasets
- **Good for:** Well-established code pre-training dataset. Predecessor to The Stack v2.

### 4.3 StarCoderData

- **Name:** StarCoderData (processed from The Stack)
- **URL:** https://huggingface.co/datasets/bigcode/starcoderdata
- **License:** Check dataset card (derived from The Stack with additional filtering)
- **Size:** 783 GB in 86 programming languages + 54 GB GitHub Issues + 13 GB Jupyter notebooks + 32 GB GitHub commits (~250 billion tokens)
- **Domains:** Clean code in 86 languages, issues, notebooks, commits
- **How to fetch:** HuggingFace Datasets (`bigcode/starcoderdata`)
- **Good for:** Ready-to-use code pre-training dataset. Cleaned, deduplicated, PII-removed. Includes SQL as one of the 86 languages.

### 4.4 CodeSearchNet

- **Name:** CodeSearchNet
- **URL:** https://github.com/github/CodeSearchNet
- **License:** Check repository (mixed)
- **Size:** ~3.5 GB; 2 million (comment, code) pairs
- **Languages:** Python, JavaScript, Ruby, Go, Java, PHP
- **How to fetch:** GitHub repository; S3 download script included
- **Good for:** Code search and retrieval training. Natural language to code mapping. Good for building code understanding capabilities.

### 4.5 GitHub Public Code on BigQuery

- **Name:** GitHub Public Dataset on Google BigQuery
- **URL:** https://cloud.google.com/blog/topics/public-datasets/github-on-bigquery-analyze-all-the-open-source-code
- **License:** Free to query (BigQuery costs apply for large queries); code licenses vary per repository
- **Size:** Terabytes of public code (ASCII files < 10 MB from open-source projects)
- **Domains:** All public GitHub repositories
- **How to fetch:** Google BigQuery SQL queries; free tier available
- **Good for:** Custom code dataset extraction. Can filter by language (SQL, C#, Python), license, stars, etc. Powerful for creating targeted training subsets.

### 4.6 GH Archive

- **Name:** GH Archive
- **URL:** https://www.gharchive.org/
- **License:** Open access
- **Size:** Continuously growing (hourly updates since 2011)
- **Domains:** All public GitHub events: pushes, PRs, issues, comments, stars, forks
- **How to fetch:** HTTP archive files (JSON, gzipped); also available on BigQuery
- **Good for:** Understanding software development workflows, PR descriptions, issue discussions, commit messages. Good for training AI to understand development context.

### 4.7 CodeParrot

- **Name:** CodeParrot Python Dataset
- **URL:** https://huggingface.co/codeparrot
- **License:** Check dataset card
- **Size:** ~50 GB of Python code
- **Domains:** Python source code from GitHub
- **How to fetch:** HuggingFace Datasets
- **Good for:** Python-specific code generation. Smaller and more focused than The Stack.

---

## 5. Multi-Domain Knowledge Bases

### 5.1 Wikidata

- **Name:** Wikidata
- **URL:** https://www.wikidata.org/wiki/Wikidata:Database_download | https://dumps.wikimedia.org/wikidatawiki/
- **License:** CC0 (public domain)
- **Size:** ~1.6 TB uncompressed (January 2026); 100M+ items
- **Domains:** Structured knowledge graph: entities, properties, relationships across all domains
- **How to fetch:** JSON/RDF dumps from Wikimedia; SPARQL endpoint at https://query.wikidata.org/; REST API
- **Good for:** Structured factual knowledge. Entity relationships, properties, taxonomies. Essential for knowledge-grounded generation and fact verification.

### 5.2 DBpedia

- **Name:** DBpedia
- **URL:** https://www.dbpedia.org/ | http://dev.dbpedia.org/Download_DBpedia
- **License:** CC-BY-SA 3.0 and GNU Free Documentation License
- **Size:** Hundreds of millions of RDF triples; extracted from Wikipedia infoboxes
- **Domains:** Structured Wikipedia knowledge: people, places, organizations, concepts
- **How to fetch:** RDF dumps from downloads.dbpedia.org; SPARQL endpoint; also Wikidata-compatible version
- **Good for:** Structured knowledge extraction from Wikipedia. Maps well to relational database concepts. Good for entity recognition and knowledge grounding.

### 5.3 OpenAlex

- **Name:** OpenAlex
- **URL:** https://openalex.org/ | https://docs.openalex.org/
- **License:** CC0 (metadata); full-text access varies by paper license
- **Size:** 474 million scholarly works, with authors, institutions, funders, citations
- **Domains:** All academic disciplines
- **How to fetch:** REST API (free, 100K credits/day with free key); monthly database snapshots for bulk download
- **Good for:** Academic knowledge graph. Excellent for training on scientific/technical literature metadata. Successor to Microsoft Academic Graph.

### 5.4 Semantic Scholar (S2)

- **Name:** Semantic Scholar Academic Graph
- **URL:** https://api.semanticscholar.org/api-docs/datasets | https://www.semanticscholar.org/
- **License:** Semantic Scholar Dataset License Agreement (free for research)
- **Size:** ~200 million papers; full corpus datasets available
- **Domains:** All academic disciplines with AI-powered features (citations, topics, TLDR summaries)
- **How to fetch:** Datasets API (bulk download); REST API (100 requests per 5 minutes, higher with auth); full corpus snapshots
- **Good for:** Rich academic paper metadata, abstracts, citations. The TLDR summaries are particularly useful for training summarization. Excellent for database/CS research papers.

### 5.5 PubGraph

- **Name:** PubGraph Knowledge Graph
- **URL:** Research paper references
- **License:** Check paper
- **Size:** 385M+ entities; unifies Wikidata, OpenAlex, Semantic Scholar
- **Domains:** Scholarly knowledge, cross-referenced
- **How to fetch:** Check paper for download instructions
- **Good for:** Unified scholarly knowledge graph combining multiple sources. Useful for training cross-referencing and knowledge integration capabilities.

### 5.6 ArXiv Dataset

- **Name:** ArXiv Bulk Data Access
- **URL:** https://arxiv.org/help/bulk_data | https://huggingface.co/datasets/arxiv_dataset
- **License:** Varies per paper (mostly arXiv license, CC-BY, public domain); bulk access requires agreement
- **Size:** 2.4M+ papers; ~1.8 TB full text (LaTeX/PDF)
- **Domains:** Physics, Mathematics, Computer Science, Quantitative Biology, Statistics, Electrical Engineering, Economics
- **How to fetch:** S3 bulk access (requester-pays); OAI-PMH metadata; HuggingFace Datasets for processed versions
- **Good for:** State-of-the-art scientific knowledge in CS, math, and related fields. LaTeX source provides structured mathematical content.

---

## 6. Feedback / RLHF / Preference Datasets

### 6.1 Anthropic HH-RLHF

- **Name:** Anthropic Human Helpfulness and Harmlessness RLHF
- **URL:** https://huggingface.co/datasets/Anthropic/hh-rlhf | https://github.com/anthropics/hh-rlhf
- **License:** MIT
- **Size:** ~170K human preference comparisons
- **Subsets:** Helpfulness (base + online + rejection sampling), Harmlessness (base + online + rejection sampling), Red Teaming
- **How to fetch:** HuggingFace Datasets (`Anthropic/hh-rlhf`); GitHub
- **Good for:** The foundational RLHF preference dataset. Training reward models for helpfulness and safety. Essential for alignment training.

### 6.2 OpenAssistant OASST2

- **Name:** OpenAssistant Conversations v2 (OASST2)
- **URL:** https://huggingface.co/datasets/OpenAssistant/oasst2
- **License:** Apache 2.0
- **Size:** 348 MB; 13,854 conversation trees; 135,174 messages; 35 languages
- **Domains:** General-purpose assistant conversations with human quality labels
- **How to fetch:** HuggingFace Datasets (`OpenAssistant/oasst2`)
- **Good for:** Multi-turn conversation training with human quality annotations. Multilingual coverage. Full conversation trees enable training on dialogue structure.

### 6.3 UltraFeedback

- **Name:** UltraFeedback
- **URL:** https://huggingface.co/datasets/openbmb/UltraFeedback | https://github.com/OpenBMB/UltraFeedback
- **License:** MIT
- **Size:** 64K prompts x 4 responses = 256K samples; GPT-4 annotated
- **Annotation dimensions:** Instruction-following, truthfulness, honesty, helpfulness
- **How to fetch:** HuggingFace Datasets; binarized version at `HuggingFaceH4/ultrafeedback_binarized`
- **Good for:** Fine-grained preference training across multiple quality dimensions. Used to train Zephyr-7B. The binarized version is ready for DPO training.

### 6.4 UltraChat

- **Name:** UltraChat (200K filtered)
- **URL:** https://huggingface.co/datasets/HuggingFaceH4/ultrachat_200k | https://github.com/thunlp/UltraChat
- **License:** MIT
- **Size:** 200K high-quality multi-turn conversations (filtered from 1.5M+)
- **Domains:** Questions about the world, writing/creation, assistance with existing materials
- **How to fetch:** HuggingFace Datasets (`HuggingFaceH4/ultrachat_200k`)
- **Good for:** Large-scale multi-turn conversation training. Good diversity of topics and conversation styles.

### 6.5 Nectar Dataset

- **Name:** Nectar (Starling Training Data)
- **URL:** HuggingFace (check Starling model card for exact reference)
- **License:** Check dataset card
- **Size:** ~60,908 samples (downsampled); part of larger preference mixture
- **Components:** Mixed from HelpSteer, PRM800k, HH-RLHF, StackExchange, UltraFeedback
- **How to fetch:** HuggingFace Datasets
- **Good for:** Curated preference data mixture. Combines multiple high-quality preference sources.

### 6.6 Tulu 2.5 Preference Data (Allen AI)

- **Name:** Tulu 2.5 Preference Data
- **URL:** https://huggingface.co/datasets/allenai/tulu-2.5-preference-data
- **License:** Check dataset card (Allen AI, likely ODC-BY or similar)
- **Size:** Check dataset card
- **Domains:** Multi-domain preference pairs
- **How to fetch:** HuggingFace Datasets (`allenai/tulu-2.5-preference-data`)
- **Good for:** State-of-the-art preference optimization data from Allen AI's Tulu project.

### 6.7 Awesome LLM Human Preference Datasets (Index)

- **Name:** Curated list of Human Preference Datasets
- **URL:** https://github.com/glgh/awesome-llm-human-preference-datasets
- **License:** Various (aggregator)
- **Size:** Catalog of all major preference datasets
- **How to fetch:** GitHub repository with links
- **Good for:** Comprehensive index to discover additional preference/RLHF datasets as they are released.

---

## 7. Instruction-Tuning Datasets

### 7.1 PLLuM Instruction Corpus (Polish)

- **Name:** PLLuM Instruction Corpus
- **URL:** https://arxiv.org/abs/2511.17161
- **License:** Check paper (CC-BY-NC-4.0 likely for full version)
- **Size:** 77K custom instructions + 100K preference optimization samples
- **Domains:** Polish-language instruction following and preference optimization
- **How to fetch:** Check paper and CYFRAGOVPL HuggingFace organization
- **Good for:** Polish-language instruction tuning. Specifically designed for alignment of Polish LLMs.

### 7.2 Self-Instruct StarCoder

- **Name:** Self-Instruct StarCoder
- **URL:** https://huggingface.co/datasets/codeparrot/self-instruct-starcoder
- **License:** Check dataset card
- **Size:** Check dataset card
- **Domains:** Code instruction-following
- **How to fetch:** HuggingFace Datasets
- **Good for:** Code-specific instruction tuning. Pairs natural language instructions with code outputs.

### 7.3 LLM Datasets (Curated Index by mlabonne)

- **Name:** LLM Datasets - Curated list for post-training
- **URL:** https://github.com/mlabonne/llm-datasets
- **License:** Various (aggregator)
- **Size:** Comprehensive catalog
- **Domains:** Instruction following, reasoning, mathematics, code, multilingual
- **How to fetch:** GitHub repository with links and descriptions
- **Good for:** Master index for discovering instruction-tuning and post-training datasets. Regularly updated.

### 7.4 LLMDataHub (Comprehensive Aggregator)

- **Name:** LLMDataHub: Awesome Datasets for LLM Training
- **URL:** https://github.com/Zjh-819/LLMDataHub
- **License:** Various (aggregator)
- **Size:** Comprehensive catalog with size, language, usage descriptions
- **How to fetch:** GitHub repository
- **Good for:** Finding specialized datasets for specific training stages (pre-training, instruction tuning, alignment).

---

## 8. Summary Matrix

| Category | Dataset | Size | License | Primary Use |
|----------|---------|------|---------|-------------|
| **Polish** | PLLuM Corpus | 140B tokens | CC-BY-NC-4.0 / open | Polish pre-training |
| **Polish** | SpeakLeash | 294M docs | Open | Polish pre-training |
| **Polish** | NKJP | 1.5B words | CC-BY / GPL | Polish linguistics |
| **Polish** | OSCAR (pl) | 49-109 GB | CC0 | Polish web text |
| **Polish** | CulturaX (pl) | Large subset | Mixed | Polish cleaned web |
| **English** | FineWeb | 15T tokens | ODC-BY | English pre-training |
| **English** | Common Pile v0.1 | 8 TB | Licensed for AI | Legally safe pre-training |
| **English** | Dolma 3 | 6T tokens | ODC-BY | Pre-training |
| **English** | RedPajama-V2 | 100B+ docs | Apache 2.0 | Multilingual pre-training |
| **English** | The Pile | 825 GiB | Mixed | Diverse pre-training |
| **English** | SlimPajama | 627B tokens | Apache 2.0 | Deduplicated pre-training |
| **Web** | Common Crawl | ~250TB/crawl | Open | Raw web data |
| **Web** | FineWeb-2 | 20 TB | ODC-BY | Multilingual web |
| **DB/SQL** | Spider | 10K questions | CC-BY-SA 4.0 | Text-to-SQL |
| **DB/SQL** | Spider 2.0 | 600 problems | Check | Enterprise text-to-SQL |
| **DB/SQL** | BIRD | 12.7K pairs | Check | Real-world text-to-SQL |
| **DB/SQL** | WikiSQL | 80K examples | BSD 3-Clause | Basic text-to-SQL |
| **DB/SQL** | SchemaPile | 221K schemas | Check | Schema understanding |
| **DB/SQL** | DBA Stack Exchange | ~1.5 GB | CC-BY-SA 4.0 | DBA expertise |
| **Code** | The Stack v2 | 67.5 TB | Mixed | Code pre-training |
| **Code** | StarCoderData | 783 GB | Check | Code pre-training |
| **Code** | CodeSearchNet | 3.5 GB | Mixed | Code search |
| **Knowledge** | Wikidata | 1.6 TB | CC0 | Knowledge graph |
| **Knowledge** | DBpedia | Large | CC-BY-SA 3.0 | Structured knowledge |
| **Knowledge** | OpenAlex | 474M works | CC0 | Academic knowledge |
| **Knowledge** | Semantic Scholar | 200M papers | Research license | Academic papers |
| **Knowledge** | Wikipedia (all) | Varies | CC-BY-SA 3.0 | Encyclopedic knowledge |
| **Knowledge** | Stack Exchange | ~98 GB | CC-BY-SA 4.0 | Expert Q&A |
| **RLHF** | Anthropic HH-RLHF | 170K pairs | MIT | Preference training |
| **RLHF** | OASST2 | 135K messages | Apache 2.0 | Conversation + prefs |
| **RLHF** | UltraFeedback | 256K samples | MIT | Multi-dim preferences |
| **RLHF** | UltraChat 200K | 200K convos | MIT | Multi-turn SFT |

---

## Recommended Training Pipeline for Database Management AI

### Phase 1: Pre-Training (Foundation)
1. **FineWeb** or **Dolma 3** as the primary English corpus
2. **PLLuM Corpus** + **SpeakLeash** for Polish language
3. **StarCoderData** or **The Stack v2** for code understanding
4. **Wikipedia** (all relevant languages) for factual grounding

### Phase 2: Domain Specialization (Continued Pre-Training)
1. **SchemaPile** for database schema understanding
2. **DBA Stack Exchange** for database administration expertise
3. **Database vendor documentation** (PostgreSQL, MySQL, SQL Server, SQLite)
4. **Spider + BIRD + WikiSQL** for text-to-SQL capabilities
5. **ArXiv** (database/CS papers) for cutting-edge knowledge

### Phase 3: Instruction Tuning (SFT)
1. **UltraChat 200K** for general conversation ability
2. **PLLuM Instruction Corpus** for Polish instruction following
3. **Self-Instruct StarCoder** for code instruction following
4. Custom instructions for database operations (may need to create)

### Phase 4: Alignment (RLHF/DPO)
1. **Anthropic HH-RLHF** for safety baseline
2. **UltraFeedback** (binarized) for multi-dimensional quality
3. **OASST2** for conversation quality
4. **PLLuM preference data** (100K samples) for Polish alignment
5. Custom preference data for database-specific safety (e.g., never drop production data without confirmation)

---

## Notes on Data Acquisition

1. **Storage requirements:** A full training pipeline will require 50-100+ TB of raw storage. Budget accordingly.
2. **HuggingFace Datasets** is the primary distribution channel for most modern datasets. Use `datasets` Python library for streaming large datasets without downloading everything.
3. **Legal considerations:** The **Common Pile v0.1** (EleutherAI, 2025) is the safest option if copyright compliance is a priority. Other datasets have varying levels of legal clarity.
4. **Deduplication matters:** Always use deduplicated versions when available (SlimPajama over RedPajama-1T, for example).
5. **Quality over quantity:** FineWeb's filtering pipeline and Dolma's curation demonstrate that careful filtering of Common Crawl outperforms raw scale.
