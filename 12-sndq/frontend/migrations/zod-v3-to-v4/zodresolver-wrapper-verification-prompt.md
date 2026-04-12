# Verification Prompt: zodResolver Wrapper Performance Claims

**Purpose**: This document provides all necessary context for an independent AI to verify the claims made about why a centralized `zodResolver` wrapper reduced TypeScript compilation metrics by ~58%. No access to the original codebase is needed.

---

## Instructions for the Reviewing AI

Please analyze the code and claims below and answer:

1. **Is the explanation for why type instantiations dropped ~58% technically correct?** Specifically, does the wrapper actually short-circuit TypeScript's overload resolution in the way described?

2. **Is the claim that the `as (...args: unknown[]) => unknown` cast prevents TypeScript from resolving the original 4-overload signature correct?** Or would TypeScript still need to resolve the original types in some other way?

3. **Are the tradeoffs accurately described?** Is anything missing or understated?

4. **Is there a better approach** that achieves the same performance benefit without the `as` cast (i.e., with better type safety)?

5. **Is the multiplier math plausible?** 4 overloads × 2 schema walks × complex constraints → ~10-20× per call site → 135 call sites → 58% total reduction?

---

## Artifact 1: The Original `zodResolver` from `@hookform/resolvers/zod` v5.2.2

This is the full source of the resolver function that TypeScript must type-check at every call site when importing directly from the library.

**File**: `node_modules/@hookform/resolvers/zod/src/zod.ts`

```typescript
import { toNestErrors, validateFieldsNatively } from '@hookform/resolvers';
import {
  FieldError,
  FieldErrors,
  FieldValues,
  Resolver,
  ResolverError,
  ResolverSuccess,
  appendErrors,
} from 'react-hook-form';
import * as z3 from 'zod/v3';
import * as z4 from 'zod/v4/core';

const isZod3Error = (error: any): error is z3.ZodError => {
  return Array.isArray(error?.issues);
};
const isZod3Schema = (schema: any): schema is z3.ZodSchema => {
  return (
    '_def' in schema &&
    typeof schema._def === 'object' &&
    'typeName' in schema._def
  );
};
const isZod4Error = (error: any): error is z4.$ZodError => {
  return error instanceof z4.$ZodError;
};
const isZod4Schema = (schema: any): schema is z4.$ZodType => {
  return '_zod' in schema && typeof schema._zod === 'object';
};

function parseZod3Issues(
  zodErrors: z3.ZodIssue[],
  validateAllFieldCriteria: boolean,
) {
  const errors: Record<string, FieldError> = {};
  for (; zodErrors.length; ) {
    const error = zodErrors[0];
    const { code, message, path } = error;
    const _path = path.join('.');
    if (!errors[_path]) {
      if ('unionErrors' in error) {
        const unionError = error.unionErrors[0].errors[0];
        errors[_path] = { message: unionError.message, type: unionError.code };
      } else {
        errors[_path] = { message, type: code };
      }
    }
    if ('unionErrors' in error) {
      error.unionErrors.forEach((unionError) =>
        unionError.errors.forEach((e) => zodErrors.push(e)),
      );
    }
    if (validateAllFieldCriteria) {
      const types = errors[_path].types;
      const messages = types && types[error.code];
      errors[_path] = appendErrors(
        _path, validateAllFieldCriteria, errors, code,
        messages ? ([] as string[]).concat(messages as string[], error.message) : error.message,
      ) as FieldError;
    }
    zodErrors.shift();
  }
  return errors;
}

function parseZod4Issues(
  zodErrors: z4.$ZodIssue[],
  validateAllFieldCriteria: boolean,
) {
  const errors: Record<string, FieldError> = {};
  for (; zodErrors.length; ) {
    const error = zodErrors[0];
    const { code, message, path } = error;
    const _path = path.join('.');
    if (!errors[_path]) {
      if (error.code === 'invalid_union' && error.errors.length > 0) {
        const unionError = error.errors[0][0];
        errors[_path] = { message: unionError.message, type: unionError.code };
      } else {
        errors[_path] = { message, type: code };
      }
    }
    if (error.code === 'invalid_union') {
      error.errors.forEach((unionError) =>
        unionError.forEach((e) => zodErrors.push(e)),
      );
    }
    if (validateAllFieldCriteria) {
      const types = errors[_path].types;
      const messages = types && types[error.code];
      errors[_path] = appendErrors(
        _path, validateAllFieldCriteria, errors, code,
        messages ? ([] as string[]).concat(messages as string[], error.message) : error.message,
      ) as FieldError;
    }
    zodErrors.shift();
  }
  return errors;
}

type RawResolverOptions = {
  mode?: 'async' | 'sync';
  raw: true;
};
type NonRawResolverOptions = {
  mode?: 'async' | 'sync';
  raw?: false;
};

// minimal interfaces to avoid assignability issues between versions
interface Zod3Type<O = unknown, I = unknown> {
  _output: O;
  _input: I;
  _def: {
    typeName: string;
  };
}

type IsUnresolved<T> = PropertyKey extends keyof T ? true : false;
type UnresolvedFallback<T, Fallback> = IsUnresolved<typeof z3> extends true
  ? Fallback
  : T;
type FallbackIssue = {
  code: string;
  message: string;
  path: (string | number)[];
};
type Zod3ParseParams = UnresolvedFallback<
  z3.ParseParams,
  {
    path?: (string | number)[];
    errorMap?: (
      iss: FallbackIssue,
      ctx: { defaultError: string; data: any },
    ) => { message: string };
    async?: boolean;
  }
>;
type Zod4ParseParams = UnresolvedFallback<
  z4.ParseContext<z4.$ZodIssue>,
  {
    readonly error?: (
      iss: FallbackIssue,
    ) => null | undefined | string | { message: string };
    readonly reportInput?: boolean;
    readonly jitless?: boolean;
  }
>;

// === THE 4 OVERLOADED TYPE SIGNATURES ===

// Overload 1: Zod v3, non-raw
export function zodResolver<Input extends FieldValues, Context, Output>(
  schema: Zod3Type<Output, Input>,
  schemaOptions?: Zod3ParseParams,
  resolverOptions?: NonRawResolverOptions,
): Resolver<Input, Context, Output>;

// Overload 2: Zod v3, raw
export function zodResolver<Input extends FieldValues, Context, Output>(
  schema: Zod3Type<Output, Input>,
  schemaOptions: Zod3ParseParams | undefined,
  resolverOptions: RawResolverOptions,
): Resolver<Input, Context, Input>;

// Overload 3: Zod v4, non-raw
export function zodResolver<
  Input extends FieldValues,
  Context,
  Output,
  T extends z4.$ZodType<Output, Input> = z4.$ZodType<Output, Input>,
>(
  schema: T,
  schemaOptions?: Zod4ParseParams,
  resolverOptions?: NonRawResolverOptions,
): Resolver<z4.input<T>, Context, z4.output<T>>;

// Overload 4: Zod v4, raw
export function zodResolver<
  Input extends FieldValues,
  Context,
  Output,
  T extends z4.$ZodType<Output, Input> = z4.$ZodType<Output, Input>,
>(
  schema: z4.$ZodType<Output, Input>,
  schemaOptions: Zod4ParseParams | undefined,
  resolverOptions: RawResolverOptions,
): Resolver<z4.input<T>, Context, z4.input<T>>;

// Implementation signature
export function zodResolver<Input extends FieldValues, Context, Output>(
  schema: object,
  schemaOptions?: object,
  resolverOptions: { mode?: 'async' | 'sync'; raw?: boolean } = {},
): Resolver<Input, Context, Output | Input> {
  // runtime implementation (irrelevant for type analysis)
  // ...
}
```

### Key types referenced

**`Resolver` from `react-hook-form` v7.72.1** (simplified):

```typescript
export type Resolver<
  TFieldValues extends FieldValues = FieldValues,
  TContext = any,
  TTransformedValues extends FieldValues | undefined = undefined,
> = (
  values: TFieldValues,
  context: TContext | undefined,
  options: ResolverOptions<TFieldValues>,
) => Promise<ResolverResult<TTransformedValues extends undefined ? TFieldValues : TTransformedValues>> | ResolverResult<TTransformedValues extends undefined ? TFieldValues : TTransformedValues>;
```

**`z4.$ZodType` from `zod/v4/core`** (simplified):

```typescript
export interface $ZodType<Output = unknown, Input = unknown, Internals extends $ZodTypeInternals = $ZodTypeInternals> {
  readonly _zod: Internals & {
    output: Output;
    input: Input;
  };
}

export interface $ZodTypeInternals<Output = unknown, Input = unknown> {
  readonly def: object;
  readonly issp: Set<string>;
  readonly disc: Map<string, Set<unknown>> | undefined;
  output: Output;
  input: Input;
}
```

---

## Artifact 2: The Wrapper

**File**: `src/lib/form/zod-resolver.ts` (actual production code)

```typescript
import { zodResolver as _zodResolver } from '@hookform/resolvers/zod';
import type { z } from 'zod';
import type { Resolver } from 'react-hook-form';

export function zodResolver<T extends z.ZodTypeAny>(
  schema: T,
  schemaOptions?: Record<string, unknown>,
  resolverOptions?: { mode?: 'async' | 'sync'; raw?: boolean },
): Resolver<z.infer<T>> {
  return (_zodResolver as (...args: unknown[]) => unknown)(
    schema,
    schemaOptions,
    resolverOptions,
  ) as Resolver<z.infer<T>>;
}
```

### Key types referenced

**`z.ZodTypeAny` from `zod` v3** (simplified):

```typescript
export type ZodTypeAny = ZodType<any, ZodTypeDef, any>;

export abstract class ZodType<
  Output = any,
  Def extends ZodTypeDef = ZodTypeDef,
  Input = Output,
> {
  readonly _type!: Output;
  readonly _output!: Output;
  readonly _input!: Input;
  readonly _def!: Def;
}
```

**`z.infer<T>`** is simply:

```typescript
export type infer<T extends ZodType<any, any, any>> = T["_output"];
```

---

## Artifact 3: Example Call Site (typical pattern)

This is the typical usage pattern repeated across ~135 files:

```typescript
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@/lib/form/zod-resolver'; // or '@hookform/resolvers/zod'

const schema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  active: z.boolean().default(false),
  role: z.enum(['admin', 'user']).default('user'),
  notes: z.string().optional(),
  address: z.object({
    street: z.string(),
    city: z.string(),
    zip: z.string(),
  }),
});

type FormValues = z.infer<typeof schema>;
// = { name: string; email: string; active: boolean; role: 'admin' | 'user'; notes?: string; address: { street: string; city: string; zip: string } }

// Note: z.input<typeof schema> would be:
// = { name: string; email: string; active?: boolean | undefined; role?: 'admin' | 'user' | undefined; notes?: string; address: { street: string; city: string; zip: string } }

export function MyForm() {
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      email: '',
      active: false,
      role: 'user',
      notes: '',
      address: { street: '', city: '', zip: '' },
    },
  });

  const onSubmit = form.handleSubmit((data) => {
    // data is typed as FormValues
    console.log(data.active); // boolean, never undefined
  });

  return <form onSubmit={onSubmit}>...</form>;
}
```

### What happens with the original resolver (no wrapper)

When `zodResolver(schema)` resolves through the original 4 overloads:

- Overload 1 matches (Zod v3, non-raw) and infers `Input = z.input<typeof schema>` and `Output = z.output<typeof schema>`
- Returns `Resolver<z.input<typeof schema>, any, z.output<typeof schema>>`
- `useForm<FormValues>` expects `resolver` to be `Resolver<FormValues, any, FormValues>` (or compatible)
- `FormValues = z.infer = z.output`, so TypeScript must check: is `Resolver<z.input, any, z.output>` assignable to `Resolver<FormValues, any, FormValues>`?
- Since `z.input` has `active?: boolean | undefined` but `FormValues` has `active: boolean`, this check **fails**
- TypeScript error: `Type 'Resolver<{ active?: boolean | undefined; ... }, any, { active: boolean; ... }>' is not assignable to type 'Resolver<{ active: boolean; ... }, any, { active: boolean; ... }>'`

### What happens with the wrapper

When `zodResolver(schema)` resolves through the wrapper's single signature:

- Matches immediately: `T = typeof schema`, `T extends z.ZodTypeAny` ✓
- Returns `Resolver<z.infer<T>>` = `Resolver<FormValues>`
- `useForm<FormValues>` expects `Resolver<FormValues, any, FormValues>` — and `Resolver<FormValues>` defaults `Context = any` and `TransformedValues = undefined`, which is compatible
- No type error

---

## Artifact 4: A Complex Real-World Schema

This is a representative schema from the codebase (purchase invoice, simplified but structurally accurate):

```typescript
const amountSchema = z.object({
  id: z.string().default(() => uuidv4()),
  amount: z.number().int(),
  hasVat: z.boolean().default(false),
  vatRate: z.number().min(0).max(100).optional(),
  hasCustomPrice: z.boolean().default(false),
  customPriceType: z.enum(['fixed', 'percentage']).optional(),
  customPriceAmount: z.number().int().optional(),
  totalAmount: z.number().int(),
  fromDate: z.string().optional(),
  toDate: z.string().optional(),
  description: z.string().optional(),
  costCategoryId: z.string().optional(),
  units: z.array(z.object({
    id: z.string().uuid(),
    selected: z.boolean(),
    share: z.number(),
    amount: z.number().int(),
    splitClearing: z.nativeEnum(AllocationSplitClearing).optional(),
    ownerSplit: z.number().min(0).max(100).optional(),
    tenantSplit: z.number().min(0).max(100).optional(),
  })),
});

const purchaseInvoiceSchema = z.object({
  supplierId: z.string().uuid().optional(),
  buildingId: z.string().uuid(),
  invoiceNumber: z.string().optional(),
  invoiceDate: z.string(),
  dueDate: z.string(),
  paymentMethod: z.enum(['pay_later', 'pay_now', 'already_paid']).default('pay_later'),
  paymentAccountId: z.string().uuid().optional(),
  structuredMessage: z.string().optional(),
  hasCreditNote: z.boolean().default(false),
  amounts: z.array(amountSchema).default([]),
  files: z.array(z.object({
    id: z.string(),
    name: z.string(),
    url: z.string(),
  })).default([]),
  // ... more fields (total ~50 fields across nested objects)
}).transform((data) => ({
  ...data,
  totalAmount: data.amounts.reduce((sum, a) => sum + a.totalAmount, 0),
}));
```

This schema has:
- ~50 fields across nested objects
- 6 `.default()` calls (id, hasVat, hasCustomPrice, paymentMethod, hasCreditNote, amounts, files)
- 1 `.transform()` (computing totalAmount)
- 2 levels of nesting (amounts → units)

For this single schema, the type difference between `z.input` and `z.output` involves:
- `id`: `string | undefined` vs `string`
- `hasVat`: `boolean | undefined` vs `boolean`
- `hasCustomPrice`: `boolean | undefined` vs `boolean`
- `paymentMethod`: `'pay_later' | 'pay_now' | 'already_paid' | undefined` vs `'pay_later' | 'pay_now' | 'already_paid'`
- `hasCreditNote`: `boolean | undefined` vs `boolean`
- `amounts`: `AmountInput[] | undefined` vs `AmountOutput[]`
- `files`: `FileInput[] | undefined` vs `FileOutput[]`
- Plus the `.transform()` adds `totalAmount` to the output type but not the input type

TypeScript must compute both of these complex types, compare them against the `useForm<FormValues>` constraint, determine they're incompatible, and then retry with the next overload — all for a single call site.

---

## Artifact 5: Measured Data

### tsc --noEmit --diagnostics (3 runs each, median)

**Baseline** (resolvers v4.1.3, RHF 7.54.2, no wrapper):

| Run | Files | Lines | Nodes | Identifiers | Symbols | Types | Instantiations | Memory (KB) | I/O (ms) | Parse (s) | Bind (s) | Check (s) | Emit (s) | Total (s) |
|-----|-------|-------|-------|-------------|---------|-------|---------------|-------------|----------|-----------|----------|-----------|----------|-----------|
| 1 | 7621 | 879,267 | 4,068,775 | 1,576,024 | 2,547,155 | 1,691,552 | 29,150,241 | 6,776,521 | 122 | 5.62 | 2.55 | 117.41 | 0.01 | 125.86 |
| 2 | 7621 | 879,267 | 4,068,775 | 1,576,024 | 2,547,155 | 1,691,552 | 29,150,241 | 6,776,633 | 114 | 5.04 | 2.55 | 117.08 | 0.01 | 121.93 |
| 3 | 7621 | 879,267 | 4,068,775 | 1,576,024 | 2,547,155 | 1,691,552 | 29,150,241 | 6,776,521 | 152 | 5.60 | 2.55 | 116.59 | 0.01 | 125.07 |

**After** (resolvers v5.2.2, RHF 7.72.1, wrapper applied):

| Run | Files | Lines | Nodes | Identifiers | Symbols | Types | Instantiations | Memory (KB) | I/O (ms) | Parse (s) | Bind (s) | Check (s) | Emit (s) | Total (s) |
|-----|-------|-------|-------|-------------|---------|-------|---------------|-------------|----------|-----------|----------|-----------|----------|-----------|
| 1 | 7845 | 912,168 | 4,220,048 | 1,630,724 | 2,608,960 | 811,954 | 12,282,340 | 2,949,276 | 113 | 5.54 | 2.69 | 73.10 | 0.01 | 81.62 |
| 2 | 7845 | 912,168 | 4,220,048 | 1,630,724 | 2,608,960 | 811,954 | 12,282,340 | 2,949,264 | 96 | 5.22 | 2.67 | 72.83 | 0.01 | 79.29 |
| 3 | 7845 | 912,168 | 4,220,048 | 1,630,724 | 2,608,960 | 811,954 | 12,282,340 | 2,949,264 | 102 | 5.36 | 2.66 | 72.93 | 0.01 | 79.34 |

### Key observations from the raw data

1. **Instantiations are 100% deterministic** — identical across all 3 runs in both before and after. This proves the reduction is real and reproducible.

2. **Types dropped by 52%** (1,691,552 → 811,954) — the compiler generates 52% fewer type nodes. This is consistent with eliminating the dual input/output type computation.

3. **Files grew** (+224 files, +32,901 lines) — the codebase was actively developed between measurements, making the improvement conservative (true same-codebase reduction would be even larger).

4. **Parse and Bind times are stable** (~5.3s and ~2.6s) — these phases don't involve type inference, confirming the reduction is purely in the Check phase.

5. **Check time dropped -37.7%** (117s → 73s) — less than the -58% instantiation drop because check time includes non-generic work (structural checks, control flow analysis, etc.) that isn't affected by the wrapper.

---

## The Claim to Verify

> A centralized zodResolver wrapper that casts `_zodResolver as (...args: unknown[]) => unknown` and returns `Resolver<z.infer<T>>` reduces TypeScript instantiations by ~58% because it eliminates the compiler's need to resolve 4 complex overloads (2 for Zod v3 + 2 for Zod v4), each requiring separate z.input and z.output type inference, at ~135 call sites across a large codebase.

> The reduction is not from using a newer/better type system (the schemas are still Zod v3). It is purely from severing the type inference chain via the `as` cast, preventing TypeScript from attempting the original resolver's overload resolution.

> The tradeoffs are: (1) loss of input/output type distinction for schemas with `.default()` and `.transform()`, which is negligible because all forms provide `defaultValues`; (2) loss of `schemaOptions` type checking, unused by any call site; (3) loss of `raw: true` return type differentiation, unused by any call site.

Please verify whether these claims are technically accurate.
