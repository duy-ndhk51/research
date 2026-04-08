# React Hook Form Best Practices

Best practices for structuring React Hook Form (RHF) in the SNDQ frontend, derived from the [bulletproof-react](https://github.com/alan2207/bulletproof-react) reference architecture and adapted for the SNDQ codebase.

---

## Architecture Overview

The form system has three layers, each solving a different problem:

### Layer 1: High-level `Form` component (render-prop)

Encapsulates `useForm` + `zodResolver` + `FormProvider` + native `<form>` in a single component. Children receive the full `UseFormReturn` via a render-prop.

```tsx
<Form
  id="create-invoice"
  schema={invoiceSchema}
  onSubmit={(values) => mutation.mutate(values)}
  options={{ defaultValues, mode: 'onChange' }}
>
  {({ register, formState, setValue, watch }) => (
    <>
      <Input label="Name" registration={register('name')} error={formState.errors.name} />
      <Button type="submit">Save</Button>
    </>
  )}
</Form>
```

**When to use:** Most forms. The render-prop pattern keeps form setup DRY and ensures `FormProvider` is always present.

**When NOT to use:** Forms that need the `useForm` instance outside of the render tree (e.g. forms where external hooks need `methods`). In those cases, call `useForm` manually and wrap with `FormProvider`.

### Layer 2: Composition primitives (FormField / FormItem / FormControl)

Fine-grained building blocks wrapping RHF's `Controller` with Radix UI for accessibility:

```tsx
<FormField
  control={form.control}
  name="email"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Email</FormLabel>
      <FormControl>
        <Input {...field} />
      </FormControl>
      <FormMessage />
    </FormItem>
  )}
/>
```

**When to use:** Complex controlled components (date pickers, rich selects, custom widgets) that cannot use `register()`.

### Layer 3: `register()` field components

Simple field components that accept a `registration` prop (the return of `register('fieldName')`):

```tsx
<Input
  label="Invoice Number"
  registration={register('invoiceNumber')}
  error={formState.errors.invoiceNumber}
/>
```

**When to use:** Native HTML inputs (`<input>`, `<textarea>`, `<select>`) where `register()` works directly.

---

## Schema Colocation

Zod schemas live **with the feature or API hook**, not in the form component folder.

```
features/invoices/
  api/
    create-invoice.ts          # schema + mutation hook
  components/
    CreateInvoiceForm.tsx       # imports schema from api/
```

This keeps the schema close to where it validates data (API boundary), not where it renders UI. Multiple forms can share the same schema.

---

## Render-prop vs Prop-drilling

### Prefer: render-prop `children(methods)`

```tsx
<Form schema={schema} onSubmit={onSubmit}>
  {({ register, formState }) => (
    <Input registration={register('name')} error={formState.errors.name} />
  )}
</Form>
```

### Avoid: destructuring and prop-drilling

```tsx
// Anti-pattern: manually destructuring and threading through
const { register, formState, setValue, getValues, watch, trigger } = methods;
// ...passing these individually to 5 different hooks and 10 components
```

When you need `methods` outside the render tree (e.g. in hooks), pass the entire `methods` object or use `useFormContext()` in child components.

---

## `register()` vs `Controller`

| Use `register()` | Use `Controller` |
|---|---|
| Native `<input>`, `<textarea>`, `<select>` | Custom components (DatePicker, Combobox, Switch) |
| Value is a string/number/boolean | Value is an object, array, or complex type |
| No controlled behavior needed | Need `onChange`/`onBlur` interception |

---

## FieldWrapper Pattern

Every field component should use a consistent wrapper for label + error display:

```tsx
export function FieldWrapper({ label, error, children, className }: FieldWrapperProps) {
  return (
    <div className={className}>
      {label && <label>{label}</label>}
      {children}
      <InlineError message={error?.message} />
    </div>
  );
}
```

Field components compose with it:

```tsx
export function Input({ label, error, registration, ...props }: InputProps) {
  return (
    <FieldWrapper label={label} error={error}>
      <input {...registration} {...props} />
    </FieldWrapper>
  );
}
```

This ensures every field has consistent error display without each component reinventing it.

---

## FormFloatingSheet Pattern

SNDQ uses `FloatingSheet` instead of `Drawer`. The `FormFloatingSheet` component encapsulates the open/close lifecycle:

```tsx
<FormFloatingSheet
  isDone={mutation.isSuccess}
  title="Create Invoice"
  submitButton={<Button form="create-invoice" type="submit">Save</Button>}
>
  <Form id="create-invoice" schema={schema} onSubmit={handleSubmit}>
    {({ register, formState }) => (/* fields */)}
  </Form>
</FormFloatingSheet>
```

Key behaviors:
- Auto-closes when `isDone` becomes `true` (e.g. mutation success)
- Manages its own open/close state internally
- Submit button uses the `form` attribute to trigger submission from outside the `<form>` element

---

## Form ID Pattern

Decouple the submit button from the form body using the HTML `form` attribute:

```tsx
// Form body (inside a sheet/drawer body)
<Form id="my-form" schema={schema} onSubmit={onSubmit}>
  {({ register }) => <Input registration={register('name')} />}
</Form>

// Submit button (in sheet/drawer footer, outside the <form>)
<Button form="my-form" type="submit">Save</Button>
```

This is essential for sheet/drawer layouts where the footer is structurally outside the form.

---

## SNDQ-specific Notes

### i18n Error Prefix (`t:`)

SNDQ uses a `t:` prefix convention in Zod error messages for translation:

```ts
z.string().min(1, 't:error_message.valuemissing')
```

The `FormError` component detects this prefix and translates via `useTranslations()`:

```tsx
if (message.startsWith('t:')) {
  const translationKey = message.slice(2);
  errorMessage = t(translationKey);
}
```

### FloatingSheet instead of Drawer

SNDQ uses `FloatingSheet` (slide-in panel from the right) where bulletproof-react uses `Drawer` (bottom sheet). The `FormFloatingSheet` component adapts this pattern.

### `useFormContext()` in Section Components

Sections inside a `FormProvider` should use `useFormContext()`, `useWatch()`, or `useController()` to read form state instead of receiving it as props. This avoids prop-drilling:

```tsx
// Good: section reads from context
export function InvoiceInfoSection() {
  const { register } = useFormContext();
  const invoiceDate = useWatch({ name: 'invoiceDate' });
  // ...
}

// Avoid: parent passes everything as props
<InvoiceInfoSection register={register} invoiceDate={invoiceDate} />
```

---

## Anti-patterns to Avoid

### 1. Excessive `watch()` in parent component

```tsx
// Anti-pattern: 8 watch() calls re-render the entire form on any change
const buildingId = watch('buildingId');
const file = watch('file');
const amounts = watch('amounts');
const senderId = watch('senderId');
// ...
```

**Fix:** Use `useWatch()` in the child components that actually need those values. This scopes re-renders to just those children.

### 2. Business logic in the form component

```tsx
// Anti-pattern: form component has 150 lines of hook orchestration
const PurchaseInvoiceForm = () => {
  const methods = useForm(...);
  const { setValue, getValues, watch, trigger } = methods;
  const peppol = usePeppolPrefill({ methods, ... });
  const supplier = useSupplierFlags({ methods, buildingId, ... });
  const actions = useInvoiceFormActions({ methods, ... });
  const fileHandling = useFileHandling({ setValue, getValues, trigger, ... });
  // ... 100 more lines before any JSX
};
```

**Fix:** Extract a `useMyForm()` hook that consolidates all setup and returns a flat object. The form component becomes purely structural.

### 3. Prop-drilling `setValue` / `getValues`

```tsx
// Anti-pattern: destructure and pass individual RHF methods
const { setValue, getValues, trigger } = methods;
useFileHandling({ setValue, getValues, trigger });
useDeferredCost({ setValue, getValues });
```

**Fix:** Pass `methods` as a whole, or have those hooks use `useFormContext()` internally if they're rendered inside `FormProvider`.

### 4. Mixing form state management with sheet state

```tsx
// Anti-pattern: one component manages both form hooks AND sheet open/close/dialogs
const Form = () => {
  const [isOpen, setIsOpen] = useState(true);
  const [showDiscardDialog, setShowDiscardDialog] = useState(false);
  const methods = useForm(...);
  // ... form logic mixed with UI state
};
```

**Fix:** Separate sheet state (`useSheetState`) from form logic (`usePurchaseInvoiceForm`). The rendering component composes both.
