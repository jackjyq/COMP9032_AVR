## Introduction

### Term

- microprocessor:
  - the implementation often central processor unit runction, or a computer in a 'ingle. large scale integrated (LSI) circuit
- microcomputer:
  - a computer built using a microprocessor and a few other components rorthe memory and 1/0
- microcontroller:
  -a microcomputer with its memoT)! and va integrated into a single chip.
  - CPU
  - ROM: program and constant data (usually)
  - RAM: variable data
  - I/O Interface
    - timer
    - PWM

### computer instruction

- operation
  - mnemonic
- operands
  - may have a source operand and a destination operand

### computer architecture

- Neumann architecture
  - CPU: central processor unit
  - memory (ROM and RAM)
  - I/O interface
  - Buses (data, address, control)

- Harvard architecture (DSP)
  - data memory
  - program memory

### I/O synchronizatino

- wait ~ ready

## AVR Programming

### memory

- Program memory
  - flash
  - application section
  - boot section

- Data memory
  - SRAM

Name              | Address     | Comments
------------------|-------------|---------------
32 Registers      | 0-1F        |  
64 I/O            | 20~5F       | IN/OUT/SBI/CBI/SBIC/SBIS
416 Ex I/O Reg    | 60~1FF      | ST/STS/STD/LD/LDS/LDD
8192 Internal SRAM| 0200-21FF   |
External SRAM     | 2200-FFFF   | optional

- EEPROM

## Parallel I/O

## Interupt

## I/O devices

## Analog I/O

## Serial Communication

## Microprocessors