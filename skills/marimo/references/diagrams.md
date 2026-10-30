# Diagrams API Reference

Create diagrams and visualizations using Mermaid.

## Mermaid Diagrams

### mo.mermaid

Render diagrams using Mermaid syntax.

```python
import marimo as mo

mo.mermaid("""
graph LR
    A[Start] --> B[Process]
    B --> C[End]
""")
```

Signature: `mo.mermaid(diagram, theme=None, theme_variables=None)`. Returns an `Html` object.

### Themes

By default the diagram follows the app's light/dark theme. Pass `theme` to pin one: `"default"`, `"base"`, `"dark"`, `"forest"`, `"neutral"`, or `"null"`.

```python
mo.mermaid(diagram, theme="neutral")

# Custom colors via Mermaid themeVariables
mo.mermaid(
    diagram,
    theme="base",
    theme_variables={
        "primaryColor": "#E8EEF5",
        "primaryTextColor": "#1F2937",
        "primaryBorderColor": "#64748B",
        "lineColor": "#475569",
    },
)
```

`theme_variables` only works with `theme="base"`. If you omit `theme`, marimo sets it to `"base"` for you; combining `theme_variables` with any other explicit theme raises `ValueError`. See [Mermaid theming](https://mermaid.js.org/config/theming.html) for the available variables.

## Flowcharts

### Basic Flowchart

```python
mo.mermaid("""
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E
""")
```

### Direction Options

- `TD` / `TB`: Top to bottom
- `BT`: Bottom to top
- `LR`: Left to right
- `RL`: Right to left

```python
mo.mermaid("""
graph LR
    A --> B --> C --> D
""")
```

### Node Shapes

```python
mo.mermaid("""
graph TD
    A[Rectangle]
    B(Rounded)
    C([Stadium])
    D[[Subroutine]]
    E[(Database)]
    F((Circle))
    G>Asymmetric]
    H{Diamond}
    I{{Hexagon}}
    J[/Parallelogram/]
    K[\Parallelogram Alt\]
""")
```

### Link Styles

```python
mo.mermaid("""
graph LR
    A --> B
    A --- C
    A -.-> D
    A ==> E
    A --text--> F
    A ---|text| G
""")
```

## Sequence Diagrams

```python
mo.mermaid("""
sequenceDiagram
    participant Client
    participant Server
    participant Database

    Client->>Server: Request
    Server->>Database: Query
    Database-->>Server: Results
    Server-->>Client: Response
""")
```

### With Activations and Notes

```python
mo.mermaid("""
sequenceDiagram
    Alice->>+John: Hello John, how are you?
    Note right of John: John thinks
    John-->>-Alice: Great!
    Alice-)John: See you later!
""")
```

## Class Diagrams

```python
mo.mermaid("""
classDiagram
    Animal <|-- Duck
    Animal <|-- Fish
    Animal : +int age
    Animal : +String gender
    Animal: +isMammal()
    Animal: +mate()

    class Duck{
        +String beakColor
        +swim()
        +quack()
    }

    class Fish{
        -int sizeInFeet
        -canEat()
    }
""")
```

## State Diagrams

```python
mo.mermaid("""
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : Start
    Processing --> Completed : Success
    Processing --> Failed : Error
    Completed --> [*]
    Failed --> Idle : Retry
""")
```

## Entity Relationship Diagrams

```python
mo.mermaid("""
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    CUSTOMER {
        string name
        string email
    }
    ORDER {
        int orderNumber
        date created
    }
    LINE-ITEM {
        string productCode
        int quantity
        float price
    }
""")
```

## Gantt Charts

```python
mo.mermaid("""
gantt
    title Project Timeline
    dateFormat YYYY-MM-DD
    section Phase 1
    Research       :a1, 2024-01-01, 30d
    Design         :a2, after a1, 20d
    section Phase 2
    Development    :a3, after a2, 60d
    Testing        :a4, after a3, 30d
    section Phase 3
    Deployment     :a5, after a4, 10d
""")
```

## Pie Charts

```python
mo.mermaid("""
pie title Distribution
    "Category A" : 40
    "Category B" : 30
    "Category C" : 20
    "Category D" : 10
""")
```

## Git Graphs

```python
mo.mermaid("""
gitGraph
    commit
    commit
    branch develop
    checkout develop
    commit
    commit
    checkout main
    merge develop
    commit
""")
```

## Dynamic Diagrams

Generate diagrams from data:

```python
def create_flowchart(steps):
    nodes = []
    links = []

    for i, step in enumerate(steps):
        nodes.append(f"    N{i}[{step}]")
        if i > 0:
            links.append(f"    N{i-1} --> N{i}")

    diagram = "graph TD\n" + "\n".join(nodes) + "\n" + "\n".join(links)
    return mo.mermaid(diagram)

create_flowchart(["Load Data", "Clean", "Transform", "Analyze", "Report"])
```

### From DataFrame

```python
def create_hierarchy(df, parent_col, child_col):
    lines = ["graph TD"]
    for _, row in df.iterrows():
        parent = row[parent_col].replace(" ", "_")
        child = row[child_col].replace(" ", "_")
        lines.append(f"    {parent} --> {child}")

    return mo.mermaid("\n".join(lines))
```

## Styling

### Node Styling

```python
mo.mermaid("""
graph LR
    A[Normal]
    B[Styled]
    C[Another]

    style B fill:#f9f,stroke:#333,stroke-width:4px
    style C fill:#bbf,stroke:#f66,stroke-width:2px,stroke-dasharray: 5 5
""")
```

### Class-based Styling

```python
mo.mermaid("""
graph LR
    A:::important --> B:::normal --> C:::warning

    classDef important fill:#f96,stroke:#333
    classDef normal fill:#9f9,stroke:#333
    classDef warning fill:#ff9,stroke:#333
""")
```

## Best Practices

### Keep Diagrams Simple

```python
# Good - clear and readable
mo.mermaid("""
graph LR
    A --> B --> C
""")

# Avoid - too complex
# Break into multiple diagrams if needed
```

### Use Meaningful Labels

```python
mo.mermaid("""
graph TD
    Start[User Request] --> Validate{Valid?}
    Validate -->|Yes| Process[Process Request]
    Validate -->|No| Error[Return Error]
""")
```

### Combine with Markdown

A cell only displays its last expression, so stack the pieces with `mo.vstack`:

```python
mo.vstack([
    mo.md("""
## System Architecture

The following diagram shows the data flow:
"""),
    mo.mermaid("""
graph LR
    Input --> Processing --> Output
"""),
    mo.md("Data flows from left to right through the system."),
])
```

Or embed the diagram in markdown with an f-string: `mo.md(f"## Data flow\n\n{mo.mermaid(diagram)}")`.

## Resources

- [Mermaid Documentation](https://mermaid.js.org/intro/)
- [Mermaid Live Editor](https://mermaid.live/)
- Supported diagram types: Flowchart, Sequence, Class, State, ER, Gantt, Pie, Git, and more
