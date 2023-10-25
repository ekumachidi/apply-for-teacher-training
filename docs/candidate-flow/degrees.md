# Degrees Flow

## Flowchart

```mermaid
---
title: Add a degree
---
flowchart TB
   %% Declarations
  review(["Degree review"])
  start(["Form page"])

  country{"Which country was the degree from?"}
  country-name[/"Which country was the degree from?"/]

  type{"What type of degree is it?"}
  foreign-type-text[/"What type of degree is it?"/]

  doctorate-type[/"What type of doctorate is it?"/]
  doctorate-type-text[/"What type of doctorate is it?"/]
  doctorate-subject[/"What subject is your degree?"/]
  doctorate-uni[/"Which university awarded your degree?"/]
  doctorate-completed{"Have you completed your degree?"}
  doctorate-year-started-no[/"What year did you start your degree?"/]
  doctorate-year-started-yes[/"What year did you start your degree?"/]
  doctorate-year-graduated[/"What year did you graduate?"/]
  doctorate-year-will-graduate[/"What year will you graduate?"/]

  level6-subject[/"What subject is your degree?"/]

  foundation-type{"What type of foundation degree is it?"}
  foundation-type-text[/"What type of degree is it?"/]
  foundation-subject[/"What subject is your degree?"/]

  bachelor-type{"What type of bachelor degree is it?"}
  bachelor-type-text[/"What type of degree is it?"/]
  bachelor-subject[/"What subject is your degree?"/]

  masters-type{"What type of masters degree is it?"}
  masters-type-text[/"What type of degree is it?"/]
  masters-subject[/"What subject is your degree?"/]

  another-subject[/"What subject is your degree?"/]

  foreign-subject[/"What subject is your degree?"/]

  %% Graph start
  start --> country
  subgraph Degree Page

    country-name ==> foreign-subject
    country ==>|Another Country| country-name
    country ==>|United Kingdom| type

    type ==>|Foundation| foundation-subject
    type ==>|Bachelors| bachelor-subject
    type ==>|Masters| masters-subject

    type ==>|Doctorate| doctorate-subject
    type ==>|Level 6| level6-subject
    type ==>|Another| another-qualification-type ==> another-subject

    subgraph foreign-path
        foreign-subject ==> foreign-type-text
    end

    subgraph masters-path
        masters-subject ==> masters-type
        masters-type-text
    end

    subgraph bachelor-path
        bachelor-subject ==> bachelor-type
        bachelor-type-text
    end

    subgraph foundation-path
        foundation-subject ==> foundation-type
        foundation-type-text
    end

    subgraph level6-path
        level6-subject
    end

    subgraph another-path
        another-subject
    end

    subgraph doctorate-path
        doctorate-subject ==> doctorate-type
        doctorate-type{"What type of doctorate is it?"}

        doctorate-type ==>|PhD| doctorate-uni
        doctorate-type ==>|DPhil| doctorate-uni

        doctorate-type ==>|EdD| doctorate-uni
        doctorate-type ==>|Other| doctorate-type-text ==> doctorate-uni

        doctorate-uni ==> doctorate-completed
        doctorate-completed ==>|Yes| doctorate-year-started-yes
        doctorate-completed ==>|No| doctorate-year-started-no

        doctorate-year-started-yes ==> doctorate-year-graduated

        doctorate-year-started-no ==> doctorate-year-will-graduate

        doctorate-year-graduated
        doctorate-year-will-graduate
    end

    %% Exiting each subgraph

    masters-type ==>|MA| shared-uni
    masters-type ==>|MSc| shared-uni
    masters-type ==>|MEd| shared-uni
    masters-type ==>|MEng| shared-uni
    masters-type ==>|Other| masters-type-text ==> shared-uni

    bachelor-type ==>|BA| shared-uni
    bachelor-type ==>|BEng| shared-uni
    bachelor-type ==>|Bsc| shared-uni
    bachelor-type ==>|BEd| shared-uni
    bachelor-type ==>|Other| bachelor-type-text ==> shared-uni

    foundation-type ==>|FdA| shared-uni
    foundation-type ==>|FDeD| shared-uni
    foundation-type ==>|FdSs| shared-uni
    foundation-type ==>|Other| foundation-type-text ==> shared-uni

    level6-subject ==> shared-uni

    another-qualification-type[/"qualification-type"/]
    another-subject ==> shared-uni

    type-text ==> shared-uni

    shared-uni[/"Which university awarded your degree?"/]
    shared-completed{"Have you completed your degree?"}
    shared-did-give-grade{"Did this qualification give a grade?"}
    shared-will-give-grade{"Will this qualification give a grade?"}
    shared-what-grade[/"What grade did you get?"/]
    shared-expected-grade[/"What grade do you expect to get?"/]

    shared-year-started[/"What year did you start your degree?"/]
    shared-year-not-started-yes-grade[/"What year did you start your degree?"/]
    shared-year-not-started-no-grade[/"What year did you start your degree?"/]
    shared-year-graduated[/"What year did you graduate?"/]
    shared-year-will-graduate[/"What year will you graduate?"/]
    shared-year-will-graduate-no-grade[/"What year will you graduate?"/]

    %% Next
    shared-uni ==> shared-completed

    %% Next
    shared-completed ==>|Yes| shared-did-give-grade
    shared-did-give-grade ==> |Yes| shared-what-grade
    shared-did-give-grade ==> |No| shared-year-started
    shared-did-give-grade ==> |I don't know| shared-year-started

    shared-what-grade ==> shared-year-started ==> shared-year-graduated
    shared-completed ==>|No| shared-will-give-grade

    shared-will-give-grade ==> |Yes| shared-expected-grade ==> shared-year-not-started-yes-grade ==> shared-year-will-graduate
    shared-will-give-grade ==> |No| shared-year-not-started-no-grade ==> shared-year-will-graduate-no-grade
    shared-will-give-grade ==> |I don't know| shared-year-not-started-no-grade

    %% Next
    shared-did-give-grade

    %% End Graph to review
    doctorate-year-will-graduate ==> review
    doctorate-year-graduated ==> review
    shared-year-graduated ==> review
    shared-year-will-graduate ==> review
    shared-year-will-graduate-no-grade ==> review
  end
```

## Paths

| Title    | Path    |
|---------------- | --------------- |
| Degree   | `candidate/application/degrees/review`   |
| What country was the degree from?    | `candidate/application/degrees/country`    |
| What type of degree is it?    | `candidate/application/degrees/level`    |
| What subject is your degree?   | `candidate/application/degrees/subject`   |
| What type of TYPE degree is it?   | `candidate/application/degrees/types`   |
| Which university awarded your degree?   | `candidate/application/degrees/university`   |
| Have you completed your degree?   | `candidate/application/degrees/completed`   |
| Did this qualification give a grade?   | `candidate/application/degrees/grade`   |
| What year did you start your degree?   | `candidate/application/degrees/start-year`   |
| What year did you graduate?   | `candidate/application/degrees/graduation-year`   |


