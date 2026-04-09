export class ButtonVisualTone {
  backgroundColor: string;
  borderColor: string;
  textColor: string;
  height: number;
  radius: number;

  constructor(backgroundColor: string, borderColor: string, textColor: string, height: number = 46, radius: number = 18) {
    this.backgroundColor = backgroundColor;
    this.borderColor = borderColor;
    this.textColor = textColor;
    this.height = height;
    this.radius = radius;
  }
}

export function getPolishPrimaryButtonTone(): ButtonVisualTone {
  return new ButtonVisualTone('#2F6BFF', '#2F6BFF', '#FFFFFF');
}

export function getPolishSecondaryButtonTone(): ButtonVisualTone {
  return new ButtonVisualTone('#EDF3FF', '#D4E2FF', '#2F6BFF');
}

export function getPolishDangerButtonTone(): ButtonVisualTone {
  return new ButtonVisualTone('#FFF4EF', '#F0D3C2', '#B8643C');
}

export function getPolishNeutralButtonTone(): ButtonVisualTone {
  return new ButtonVisualTone('#FFFFFF', '#E4DACF', '#615B53');
}

export function getPolishGhostButtonTone(): ButtonVisualTone {
  return getPolishNeutralButtonTone();
}

export class AuthSurfaceTone {
  backgroundColor: string;
  borderColor: string;
  radius: number;

  constructor(backgroundColor: string, borderColor: string, radius: number = 24) {
    this.backgroundColor = backgroundColor;
    this.borderColor = borderColor;
    this.radius = radius;
  }
}

export function getAuthHeroSurfaceTone(): AuthSurfaceTone {
  return new AuthSurfaceTone('#FFFCF8', '#E4D9CC', 26);
}

export function getAuthInputSurfaceTone(): AuthSurfaceTone {
  return new AuthSurfaceTone('#FFFFFF', '#E5DDD1', 18);
}

export class AuthSplitButtonLayout {
  leftWeight: number;
  rightWeight: number;
  gap: number;

  constructor(leftWeight: number, rightWeight: number, gap: number) {
    this.leftWeight = leftWeight;
    this.rightWeight = rightWeight;
    this.gap = gap;
  }
}

export function getAuthSymmetricSplitButtonLayout(): AuthSplitButtonLayout {
  return new AuthSplitButtonLayout(1, 1, 12);
}
