---
title: BriVault Audit Report
author: Elia Bordoni
date: October 7, 2025
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
\centering
\begin{figure}[h]
\centering
\includegraphics[width=0.5\textwidth]{logo.pdf}
\end{figure}
\vspace\*{2cm}
{\Huge\bfseries BriVault Audit Report\par}
\vspace{1cm}
{\Large Version 1.0\par}
\vspace{2cm}
{\Large\itshape Elia Bordoni\par}
\vfill
{\large \today\par}
\end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: [Elia Bordoni](https://elia-bordoni-blockchain-security-researcher.vercel.app/)

<!-- Lead Auditors:
- xxxxxxx -->

# Table of Contents

- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
  - [High](#high)
  - [Medium](#medium)
  - [Low](#low)
  - [Informational](#informational)
  - [Gas](#gas)

# Protocol Summary

This smart contract implements a tournament betting vault using the ERC4626 tokenized vault standard. It allows users to deposit an ERC20 asset to bet on a team, and at the end of the tournament, winners share the pool based on the value of their deposits.
Participants can deposit tokens into the vault before the tournament begins, selecting a team to bet on. After the tournament ends and the winning team is set by the contract owner, users who bet on the correct team can withdraw their share of the total pooled assets.
The vault is fully ERC4626-compliant, enabling integrations with DeFi protocols and front-end tools that understand tokenized vaults.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details

**Commit hash:**

```

```

## Scope

./src/

- briTechToken.sol
- beiVault.sol

## Roles

**1. Owner:**

- RESPONSIBILITIES:

  - Only the owner can set the winner after the event ends.

- LIMITATIONS:
  - Onwer cannot partecipate to the event

**2. Users:**

- RESPONSIBILITIES:

  - Users have to send in asset to the contract (deposit + participation fee).
  - Users should only join events only after they have made deposit.

- LIMITATIONS:
  - Users should not be able to deposit once the event starts.

# Executive Summary

_The entire audit was carried out exclusively through manual review._

## Issues found

| Severity | Number of issues found |
| -------- | ---------------------- |
| High     |                        |
| Medium   |                        |
| Low      |                        |
| Total    |                        |

# Findings

## High

## Medium

## Low

## Informational

## Gas
