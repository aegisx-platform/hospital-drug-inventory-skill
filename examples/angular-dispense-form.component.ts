// Dispensing form — see references/dispensing-substore.md and references/patterns.md §5 (FEFO)
// Generic name is primary (เกณฑ์จริยธรรม 2564 ข้อ 13); trade name is secondary.

import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { DispensingService } from './dispensing.service';

@Component({
  selector: 'ax-dispense-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="dispense()" class="ax-flex ax-flex-col ax-gap-3">
      <mat-form-field appearance="outline">
        <mat-label>ชื่อสามัญ (Generic)</mat-label>
        <input matInput formControlName="genericName" required />
        @if (selectedLot(); as lot) {
          <mat-hint>Trade: {{ lot.tradeName }} · Lot {{ lot.lotNo }} · EXP {{ lot.expiryDate | date }}</mat-hint>
        }
      </mat-form-field>

      <mat-form-field appearance="outline">
        <mat-label>จำนวน (base unit)</mat-label>
        <input matInput type="number" formControlName="quantity" min="1" required />
      </mat-form-field>

      <button mat-flat-button color="primary" type="submit" [disabled]="form.invalid">
        จ่ายยา
      </button>
    </form>
  `,
})
export class DispenseFormComponent {
  private fb = inject(FormBuilder);
  private svc = inject(DispensingService);

  selectedLot = signal<{ tradeName: string; lotNo: string; expiryDate: Date } | null>(null);

  form = this.fb.nonNullable.group({
    genericName: ['', Validators.required],
    quantity: [1, [Validators.required, Validators.min(1)]],
  });

  async dispense() {
    const { genericName, quantity } = this.form.getRawValue();
    // Service picks FEFO lot (orderBy expiryDate asc) and writes StockJournal with direction OUT.
    const result = await this.svc.dispenseByGeneric(genericName, quantity);
    this.selectedLot.set(result.lot);
  }
}
