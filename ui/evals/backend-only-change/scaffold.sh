#!/usr/bin/env bash
# A rounding bug in a helper. Nothing visual changes, so no style or component may.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src/styles src/components src/lib
cat >src/styles/tokens.css <<'CSS'
:root {
  --space-2: 8px;
  --space-4: 16px;
  --space-6: 24px;
  --radius-2: 8px;
  --color-surface: #ffffff;
  --color-text: #1b1d21;
  --color-danger: #c62828;
  --color-border: #e3e5e8;
}
CSS
cat >src/components/dialog.css <<'CSS'
.dialog {
  width: 480px;
  padding: var(--space-4);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-2);
  background: var(--color-surface);
}
.dialog__header,
.dialog__body,
.dialog__footer {
  padding-inline: var(--space-4);
}
.dialog__footer {
  display: flex;
  gap: var(--space-2);
  justify-content: flex-end;
}
CSS
cat >src/components/Dialog.tsx <<'TSX'
import "./dialog.css";
import type { ReactNode } from "react";

export function Dialog(props: { title: string; children: ReactNode; footer?: ReactNode; open: boolean }) {
  if (!props.open) return null;
  return (
    <div role="dialog" aria-modal="true" aria-label={props.title} className="dialog">
      <header className="dialog__header"><h2>{props.title}</h2></header>
      <div className="dialog__body">{props.children}</div>
      {props.footer ? <footer className="dialog__footer">{props.footer}</footer> : null}
    </div>
  );
}
TSX
cat >src/components/Button.tsx <<'TSX'
import type { ButtonHTMLAttributes } from "react";

export function Button(props: ButtonHTMLAttributes<HTMLButtonElement> & { tone?: "default" | "danger" }) {
  const { tone = "default", ...rest } = props;
  return <button {...rest} className={tone === "danger" ? "button button--danger" : "button"} />;
}
TSX
cat >src/lib/price.ts <<'TS'
export function toCents(amount: number): number {
  return Math.floor(amount * 100);
}
TS
git add -A
git commit -qm "dialog, button, price helper"
git branch -M main
git checkout -q -b feature/settings
cat >src/lib/price.test.ts <<'TS'
import { toCents } from "./price";
if (toCents(0.29) !== 29) throw new Error("toCents(0.29) should be 29");
TS
git add -A
